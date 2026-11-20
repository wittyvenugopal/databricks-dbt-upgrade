-- Disabled leftover (models/legacy is +enabled: false), so dbt 1.x never compiles it.
-- V2: calls a macro and a var that no longer exist.
select {{ old_removed_macro('x') }} as a, {{ var('retired_var') }} as b
