// src/hooks/useApi.ts
// Hook générique pour appels API (sans boucle infinie)

import { useState, useEffect, useRef, useCallback } from 'react';
import { getErrorMessage } from '../api/client';

interface UseApiOptions<T> {
  immediate?: boolean;
  initialData?: T;
}

export function useApi<T>(
  fetchFn: () => Promise<T>,
  options: UseApiOptions<T> = {}
) {
  const { immediate = true, initialData } = options;

  const [data, setData] = useState<T | undefined>(initialData);
  const [isLoading, setIsLoading] = useState(immediate);
  const [error, setError] = useState<string | null>(null);

  const fetchFnRef = useRef(fetchFn);
  useEffect(() => {
    fetchFnRef.current = fetchFn;
  }, [fetchFn]);

  const fetch = useCallback(async () => {
    setIsLoading(true);
    setError(null);

    try {
      const result = await fetchFnRef.current();
      setData(result);
      return result;
    } catch (err) {
      setError(getErrorMessage(err));
      throw err;
    } finally {
      setIsLoading(false);
    }
  }, []); 


  const hasFetched = useRef(false);
  useEffect(() => {
    if (immediate && !hasFetched.current) {
      hasFetched.current = true;
      fetch().catch(() => {});
    }
  }, [immediate, fetch]);

  return { data, isLoading, error, refetch: fetch };
}