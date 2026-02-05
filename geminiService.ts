
import { GoogleGenAI, Type } from "@google/genai";

const ai = new GoogleGenAI({ apiKey: process.env.API_KEY || '' });

export const scanIngredients = async (base64Image: string) => {
  const model = ai.models.generateContent({
    model: 'gemini-2.5-flash-image',
    contents: {
      parts: [
        {
          inlineData: {
            mimeType: 'image/jpeg',
            data: base64Image,
          },
        },
        {
          text: 'Analiza esta imagen de ingredientes. Identifica 3-5 artículos distintos. Para cada uno, proporciona el nombre en ESPAÑOL, un nivel de confianza (0-100), y una cantidad probable. Devuelve un array JSON de objetos con las propiedades: name, confidence, quantity.',
        },
      ],
    },
    config: {
      responseMimeType: 'application/json',
      responseSchema: {
        type: Type.ARRAY,
        items: {
          type: Type.OBJECT,
          properties: {
            name: { type: Type.STRING },
            confidence: { type: Type.NUMBER },
            quantity: { type: Type.STRING },
          },
          required: ['name', 'confidence', 'quantity']
        }
      }
    }
  });

  const response = await model;
  return JSON.parse(response.text || '[]');
};

export const generateWasteInsight = async (pantryItems: string) => {
  const model = ai.models.generateContent({
    model: 'gemini-3-flash-preview',
    contents: `Basado en estos artículos de la despensa y su vencimiento: ${pantryItems}. Proporciona un consejo corto, dinámico y accionable en ESPAÑOL para que el usuario reduzca el desperdicio. Mantente por debajo de 30 palabras.`,
  });
  const response = await model;
  return response.text;
};
