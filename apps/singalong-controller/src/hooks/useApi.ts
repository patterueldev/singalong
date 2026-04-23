import { useState, useCallback } from 'react';
import { type AxiosError } from 'axios';
import apiClient from '../services/api';

interface UseApiState<T> {
  data: T | null;
  loading: boolean;
  error: AxiosError | null;
}

export function useApi<T>() {
  const [state, setState] = useState<UseApiState<T>>({
    data: null,
    loading: false,
    error: null,
  });

  const request = useCallback(
    async (method: 'get' | 'post' | 'put' | 'delete', url: string, data?: object) => {
      setState({ data: null, loading: true, error: null });
      try {
        const response = await apiClient[method]<T>(url, data);
        setState({ data: response.data, loading: false, error: null });
        return response.data;
      } catch (error) {
        const axiosError = error as AxiosError;
        setState({ data: null, loading: false, error: axiosError });
        throw axiosError;
      }
    },
    []
  );

  return { ...state, request };
}
