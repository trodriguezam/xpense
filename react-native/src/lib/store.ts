// Mini bus de eventos: las pantallas se refrescan cuando cambian los datos.
import { useEffect, useState } from "react";

type Fn = () => void;
const subs = new Set<Fn>();

export const emitir = () => subs.forEach((f) => f());

export function useVersionDatos(): number {
  const [v, setV] = useState(0);
  useEffect(() => {
    const f = () => setV((x) => x + 1);
    subs.add(f);
    return () => { subs.delete(f); };
  }, []);
  return v;
}
