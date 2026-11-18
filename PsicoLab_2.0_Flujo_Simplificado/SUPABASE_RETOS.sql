-- Ejecutar UNA VEZ en Supabase > SQL Editor antes del despliegue.
-- Conserva intactas las respuestas existentes. Se puede volver a ejecutar.
CREATE TABLE IF NOT EXISTS public.retos (
    id UUID PRIMARY KEY,
    registro_id UUID NOT NULL REFERENCES public.respuestas(id) ON DELETE CASCADE,
    huella TEXT NOT NULL,
    modelo TEXT NOT NULL DEFAULT 'B3' CHECK (modelo = 'B3'),
    entradas JSONB NOT NULL,
    pred_b3 TEXT[] NOT NULL CHECK (
        cardinality(pred_b3) = 3 AND pred_b3 <@ ARRAY['A','B','C']::TEXT[]
        AND array_position(pred_b3, NULL) IS NULL),
    decisiones TEXT[] CHECK (decisiones IS NULL OR (
        cardinality(decisiones) = 3 AND decisiones <@ ARRAY['A','B','C']::TEXT[]
        AND array_position(decisiones, NULL) IS NULL)),
    coincidencias INTEGER CHECK (coincidencias BETWEEN 0 AND 3),
    creado_en TIMESTAMPTZ NOT NULL DEFAULT now(),
    finalizado_en TIMESTAMPTZ,
    UNIQUE (registro_id, huella),
    CHECK ((decisiones IS NULL AND coincidencias IS NULL AND finalizado_en IS NULL)
        OR (decisiones IS NOT NULL AND coincidencias IS NOT NULL AND finalizado_en IS NOT NULL))
);
ALTER TABLE public.retos ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.retos FROM anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.retos TO service_role;
NOTIFY pgrst, 'reload schema';
