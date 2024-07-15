require('./test-class')

require('./test-bigint')
require('./test-color')
require('./test-emitter')
require('./test-iterable')
require('./test-mutex')
require('./test-logger')
require('./test-time')

require('./test-clock') -- Clock depends on Emitter
require('./test-date') -- Date depends on Time
require('./test-stopwatch') -- Stopwatch depends on Time