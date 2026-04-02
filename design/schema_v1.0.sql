-- 资产管理系统 - 数据库设计文档 v1.0
-- 创建日期: 2025-01-20
-- 说明: 此文件定义了本地SQLite数据库的结构，是手机端与未来电脑端数据同步的基石。
-- 注意: 任何对表结构的修改都应在此记录，并考虑版本升级策略。

-- ======================= 核心资产表 =======================
-- 存储所有资产物品（如手机、相机、电脑等）的核心信息。
CREATE TABLE assets (
    id TEXT PRIMARY KEY,            -- 全局唯一标识符。使用UUID格式，确保各设备离线创建时也不会冲突。
    name TEXT NOT NULL,             -- 资产名称，如 “iPhone 15 Pro”
    category TEXT,                  -- 分类，如 “电子产品/手机”
    price REAL NOT NULL,            -- 购买价格（元）
    purchase_date TEXT NOT NULL,    -- 购买日期，ISO8601格式 (YYYY-MM-DD)
    location TEXT,                  -- 当前位置，如 “家里”, “公司”, “身上”
    notes TEXT,                     -- 备注信息
    image_url TEXT,                 -- 资产图片的本地存储路径或URL

    -- >>>>>>>>> 同步核心字段 <<<<<<<<<
    -- 以下三个字段是实现“离线优先、智能同步”架构的关键，严禁随意修改其逻辑。
    created_at TEXT NOT NULL,       -- 记录创建时间，ISO8601格式 (YYYY-MM-DD HH:MM:SS.SSS)
    updated_at TEXT NOT NULL,       -- 记录最后更新时间。同步时解决冲突的最高法则：始终信任更大的updated_at。
    is_deleted INTEGER NOT NULL DEFAULT 0 CHECK (is_deleted IN (0, 1)) -- 软删除标记。1表示已删除。

    -- 索引优化
    CHECK (is_deleted IN (0, 1))
);
-- 为频繁查询和排序的字段创建索引，提升性能。
CREATE INDEX idx_assets_updated ON assets (updated_at);
CREATE INDEX idx_assets_deleted ON assets (is_deleted);

-- ======================= 同步日志表 =======================
-- 为实现未来的双向同步功能预留。记录所有本地发生的变更，用于在网络连通时同步给其他设备。
CREATE TABLE sync_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    asset_id TEXT NOT NULL,         -- 关联的资产ID
    operation TEXT NOT NULL CHECK (operation IN ('CREATE', 'UPDATE', 'DELETE')), -- 操作类型
    changed_data TEXT NOT NULL,     -- 本次变更时，该条资产的完整JSON快照。用于可靠地重放操作。
    created_at TEXT NOT NULL        -- 日志产生的时间
);
CREATE INDEX idx_sync_log_created ON sync_log (created_at);
CREATE INDEX idx_sync_log_asset ON sync_log (asset_id);

-- ======================= 示例数据 =======================
-- 以下INSERT语句仅用于开发阶段测试，与代码中的示例数据对应。
-- INSERT INTO assets (
--     id, name, category, price, purchase_date, location, notes, created_at, updated_at, is_deleted
-- ) VALUES (
--     'sample-001',
--     '示例 iPhone',
--     '电子产品/手机',
--     5999.0,
--     date('now', '-180 days'), -- 180天前购买
--     '身上',
--     '这是自动生成的示例数据，长按可删除',
--     datetime('now'),
--     datetime('now'),
--     0
-- );

-- ======================= 设计原则说明 =======================
-- 1. 【离线优先】每个终端设备都拥有完整的、可独立工作的数据库副本。
-- 2. 【唯一标识】使用UUID作为主键，是分布式（多设备）数据同步的前提。
-- 3. 【软删除】使用`is_deleted`标记删除，而非物理删除，便于数据同步和恢复。
-- 4. 【时间戳仲裁】`updated_at`字段是解决多设备数据冲突的唯一依据（最新者胜出）。
-- 5. 【可追溯性】`sync_log`表记录了所有变更流水，确保同步过程可追溯、可重放。