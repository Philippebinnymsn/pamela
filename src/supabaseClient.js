import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

export const supabaseConfigurado = Boolean(supabaseUrl && supabaseAnonKey);

// Se as variáveis não estiverem configuradas, criamos um cliente "vazio"
// só pra não quebrar o import — o app mostra uma tela avisando o que falta.
export const supabase = supabaseConfigurado
  ? createClient(supabaseUrl, supabaseAnonKey)
  : createClient('https://placeholder.supabase.co', 'placeholder-key');
