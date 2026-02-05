
export interface PantryItem {
  id: string;
  name: string;
  category: 'Lácteos' | 'Verduras' | 'Proteínas' | 'Despensa' | 'Panadería';
  quantity: string;
  expiryDays: number;
  image: string;
}

export interface Recipe {
  id: string;
  title: string;
  time: string;
  difficulty: 'Fácil' | 'Media' | 'Difícil';
  matchPercentage: number;
  image: string;
  missingIngredients: string[];
  isZeroWaste?: boolean;
}

export type ViewType = 'Despensa' | 'Planificador' | 'Escáner' | 'Impacto' | 'Perfil' | 'Recetas';

export interface ScanResult {
  name: string;
  confidence: number;
  quantity: string;
  image: string;
}
