require('strict').on()

local t = require('luatest')
local g = t.group()

local metrics = require('metrics')
local fun = require('fun')

g.after_each(function()
    -- Delete all collectors and global labels
    metrics.clear()
end)

g.before_each(function()
    -- Enable default metrics collections
    metrics.enable_default_metrics()
end)

g.before_all(function()
    box.cfg{}
    local s_vinyl = box.schema.space.create(
        'test_space',
        {if_not_exists = true, engine = 'vinyl'})
    s_vinyl:create_index('pk', {if_not_exists = true})
    metrics.clear()
end)

g.test_vinyl_metrics_present = function()
    metrics.invoke_callbacks()
    local metrics_cnt = fun.iter(metrics.collect()):filter(function(x)
        return x.metric_name:find('tnt_vinyl')
    end):length()
    t.assert_equals(metrics_cnt, 19)
end
