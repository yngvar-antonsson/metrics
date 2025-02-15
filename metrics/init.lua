-- vim: ts=4:sw=4:sts=4:expandtab

local checks = require('checks')
local log = require('log')

local Registry = require('metrics.registry')

local Counter = require('metrics.collectors.counter')
local Gauge = require('metrics.collectors.gauge')
local Histogram = require('metrics.collectors.histogram')
local Summary = require('metrics.collectors.summary')

local registry = rawget(_G, '__metrics_registry')
if not registry then
    registry = Registry.new()
end
rawset(_G, '__metrics_registry', registry)

local function collectors()
    return registry.collectors
end

local function register_callback(...)
    return registry:register_callback(...)
end

local function unregister_callback(...)
    return registry:unregister_callback(...)
end

local function invoke_callbacks()
    return registry:invoke_callbacks()
end

local function collect()
    return registry:collect()
end

local function clear()
    registry:clear()
end

local function counter(name, help)
    checks('string', '?string')

    return registry:find_or_create(Counter, name, help)
end

local function gauge(name, help)
    checks('string', '?string')

    return registry:find_or_create(Gauge, name, help)
end

local function histogram(name, help, buckets)
    checks('string', '?string', '?table')
    if buckets ~= nil and not Histogram.check_buckets(buckets) then
        error('Invalid value for buckets')
    end

    return registry:find_or_create(Histogram, name, help, buckets)
end

local function summary(name, help, objectives, params)
    checks('string', '?string', '?table', {
        age_buckets_count = '?number',
        max_age_time = '?number',
    })
    if objectives ~= nil and not Summary.check_quantiles(objectives) then
        error('Invalid value for objectives')
    end
    params = params or {}
    local age_buckets_count = params.age_buckets_count
    local max_age_time = params.max_age_time
    if max_age_time and max_age_time <= 0 then
        error('Max age must be positive')
    end
    if age_buckets_count and age_buckets_count < 1 then
        error('Age buckets count must be greater or equal than one')
    end
    if (max_age_time and not age_buckets_count) or (not max_age_time and age_buckets_count) then
        error('Age buckets count and max age must be present only together')
    end

    return registry:find_or_create(Summary, name, help, objectives, params)
end

local function set_global_labels(label_pairs)
    checks('?table')

    label_pairs = label_pairs or {}

    -- Verify label table
    for k, _ in pairs(label_pairs) do
        if type(k) ~= 'string' then
            error(("bad label key (string expected, got %s)"):format(type(k)))
        end
    end

    registry:set_labels(label_pairs)
end

return {
    registry = registry,

    counter = counter,
    gauge = gauge,
    histogram = histogram,
    summary = summary,

    INF = math.huge,
    NAN = math.huge * 0,

    clear = clear,
    collectors = collectors,
    register_callback = register_callback,
    unregister_callback = unregister_callback,
    invoke_callbacks = invoke_callbacks,
    set_global_labels = set_global_labels,
    enable_default_metrics = function(include, exclude)
        require('metrics.default_metrics.tarantool').enable(include, exclude)
    end,
    enable_cartridge_metrics = function()
        log.warn('metrics.enable_cartridge_metrics() is deprecated. Use metrics.enable_default_metrics() instead.')
        return require('metrics.cartridge').enable()
    end,
    http_middleware = require('metrics.http_middleware'),
    collect = collect,
}
