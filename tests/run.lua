require('./test-class')

require('./test-bitfield')
require('./test-color')
require('./test-emitter')
require('./test-time')
require('./test-mutex')

require('./test-clock') -- Clock depends on Emitter
require('./test-date') -- Date depends on Time
require('./test-stopwatch') -- Stopwatch depends on Time
