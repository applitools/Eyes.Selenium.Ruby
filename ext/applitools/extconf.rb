require 'mkmf'
$CFLAGS << ' -Wall'
create_makefile('applitools/resampling_fast')
