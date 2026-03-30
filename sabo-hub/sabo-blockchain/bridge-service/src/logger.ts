type LogLevel = 'INFO' | 'WARN' | 'ERROR' | 'DEBUG';

function timestamp(): string {
  return new Date().toISOString();
}

function log(level: LogLevel, module: string, message: string, data?: unknown): void {
  const prefix = `[${timestamp()}] [${level}] [${module}]`;
  if (data) {
    console.log(`${prefix} ${message}`, data);
  } else {
    console.log(`${prefix} ${message}`);
  }
}

export const logger = {
  info: (module: string, msg: string, data?: unknown) => log('INFO', module, msg, data),
  warn: (module: string, msg: string, data?: unknown) => log('WARN', module, msg, data),
  error: (module: string, msg: string, data?: unknown) => log('ERROR', module, msg, data),
  debug: (module: string, msg: string, data?: unknown) => log('DEBUG', module, msg, data),
};
