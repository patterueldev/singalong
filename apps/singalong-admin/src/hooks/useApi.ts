import { useState, useCallback } from 'react'
import api from '../services/api'

interface UseApiOptions {
  onSuccess?: (data: unknown) => void
  onError?: (error: Error) => void
}

export const useApi = (options?: UseApiOptions) => {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<Error | null>(null)

  const request = useCallback(
    async (method: string, url: string, data?: unknown) => {
      setLoading(true)
      setError(null)
      try {
        const response = await api.request({
          method,
          url,
          data,
        })
        options?.onSuccess?.(response.data)
        return response.data
      } catch (err) {
        const error = err instanceof Error ? err : new Error(String(err))
        setError(error)
        options?.onError?.(error)
        throw error
      } finally {
        setLoading(false)
      }
    },
    [options]
  )

  return { request, loading, error }
}
