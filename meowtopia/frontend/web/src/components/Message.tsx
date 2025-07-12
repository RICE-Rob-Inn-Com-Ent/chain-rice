import React from "react";

const Message: React.FC<{ message: string }> = ({ message }) => (
  <div style={{ color: 'red', marginBottom: '1rem' }}>{message}</div>
);

export default Message; 