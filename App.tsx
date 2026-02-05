
import React, { useState } from 'react';
import Layout from './components/Layout';
import PantryView from './views/PantryView';
import ScannerView from './views/ScannerView';
import RecipeView from './views/RecipeView';
import ImpactView from './views/ImpactView';
import { INITIAL_PANTRY } from './constants';
import { ViewType, PantryItem, ScanResult } from './types';

const App: React.FC = () => {
  const [activeTab, setActiveTab] = useState<ViewType>('Despensa');
  const [pantry, setPantry] = useState<PantryItem[]>(INITIAL_PANTRY);

  const handleAddItems = (scanned: ScanResult[]) => {
    const newItems: PantryItem[] = scanned.map((s, idx) => ({
      id: `new-${Date.now()}-${idx}`,
      name: s.name,
      category: 'Verduras', 
      quantity: s.quantity,
      expiryDays: 7, 
      image: s.image
    }));
    setPantry(prev => [...newItems, ...prev]);
    setActiveTab('Despensa');
  };

  const renderContent = () => {
    switch (activeTab) {
      case 'Despensa':
        return <PantryView items={pantry} />;
      case 'Escáner':
        return <ScannerView onAddItems={handleAddItems} />;
      case 'Recetas':
        return <RecipeView />;
      case 'Impacto':
        return <ImpactView />;
      case 'Planificador':
        return <PlannerView />;
      default:
        return <PantryView items={pantry} />;
    }
  };

  return (
    <Layout activeTab={activeTab} setActiveTab={setActiveTab}>
      {renderContent()}
    </Layout>
  );
};

const PlannerView = () => (
  <div className="p-4 flex flex-col items-center justify-center h-full opacity-60">
    <span className="material-symbols-outlined text-6xl mb-4">calendar_month</span>
    <h2 className="text-xl font-bold">Planificador de Comidas</h2>
    <p className="text-sm text-center">Organiza tu semana para reducir el desperdicio al máximo.</p>
  </div>
);

export default App;
