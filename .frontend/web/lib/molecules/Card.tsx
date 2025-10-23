import React from 'react';

export interface CardProps {
  title?: string;
  children?: React.ReactNode;
}

export const Card: React.FC<CardProps> = ({ title, children }) => {
  return (
    <div className="p-4 border rounded-md shadow-sm bg-white">
      {title && <h3 className="font-semibold mb-2">{title}</h3>}
      <div>{children}</div>
    </div>
  );
};

export default Card;
