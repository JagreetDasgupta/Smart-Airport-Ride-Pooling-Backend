import redis from '../config/redis'
import { v4 as uuidv4 } from 'uuid'

export class ConcurrencyManager {
  async withLock<T>(key: string, timeout: number, fn: () => Promise<T>): Promise<T> {
    const lockId = uuidv4()
    const lockKey = `lock:${key}`
    const acquired = await redis.set(lockKey, lockId, 'PX', timeout, 'NX')
    if (!acquired) {
      throw new Error(`Could not acquire lock for ${key}`)
    }
    try {
      return await fn()
    } finally {
      const script = `
        if redis.call("get", KEYS[1]) == ARGV[1] then
          return redis.call("del", KEYS[1])
        else
          return 0
        end
      `
      await redis.eval(script, 1, lockKey, lockId)
    }
  }
}
