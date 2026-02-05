
import { PantryItem, Recipe } from './types';

export const INITIAL_PANTRY: PantryItem[] = [
  {
    id: '1',
    name: 'Leche Entera Orgánica',
    category: 'Lácteos',
    quantity: '1.5L Restante',
    expiryDays: 2,
    image: 'https://images.unsplash.com/photo-1550583724-1277f29b672e?auto=format&fit=crop&q=80&w=200'
  },
  {
    id: '2',
    name: 'Aguacates Maduros',
    category: 'Verduras',
    quantity: '2 Unidades',
    expiryDays: 4,
    image: 'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?auto=format&fit=crop&q=80&w=200'
  },
  {
    id: '3',
    name: 'Huevos de Pastoreo',
    category: 'Proteínas',
    quantity: '12 Unidades',
    expiryDays: 12,
    image: 'https://images.unsplash.com/photo-1506976785307-8732e854ad03?auto=format&fit=crop&q=80&w=200'
  },
  {
    id: '4',
    name: 'Yogur Griego',
    category: 'Lácteos',
    quantity: '500g',
    expiryDays: 9,
    image: 'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&q=80&w=200'
  }
];

export const SUGGESTED_RECIPES: Recipe[] = [
  {
    id: 'r1',
    title: 'Pimientos Rellenos Keto',
    time: '35 min',
    difficulty: 'Media',
    matchPercentage: 100,
    image: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&q=80&w=800',
    missingIngredients: [],
    isZeroWaste: true
  },
  {
    id: 'r2',
    title: 'Pasta con Camarones al Ajillo',
    time: '20 min',
    difficulty: 'Fácil',
    matchPercentage: 90,
    image: 'https://images.unsplash.com/photo-1563379926898-05f4575a45d8?auto=format&fit=crop&q=80&w=800',
    missingIngredients: ['Perejil']
  },
  {
    id: 'r3',
    title: 'Bowl de Quinoa y Vegetales',
    time: '15 min',
    difficulty: 'Fácil',
    matchPercentage: 75,
    image: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&q=80&w=800',
    missingIngredients: ['Aguacate', 'Tahin']
  }
];
