// Ambient type declarations for Supabase Edge Functions (Deno runtime)
// This enables full IDE IntelliSense and eliminates TypeScript diagnostics when editing outside Deno CLI.

declare namespace Deno {
  export function serve(
    handler: (req: Request) => Promise<Response> | Response
  ): void;

  export const env: {
    get(key: string): string | undefined;
  };
}

declare module 'https://esm.sh/@supabase/supabase-js@2' {
  export function createClient(
    supabaseUrl: string,
    supabaseKey: string,
    options?: Record<string, unknown>
  ): any;
}

declare module 'https://*' {
  const content: any;
  export default content;
}
