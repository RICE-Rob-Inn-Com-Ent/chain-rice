export const Title: React.FC = () => {
  return (
    <>
      <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
        {messages.title}
      </h2>
      <p className="mt-2 text-center text-sm text-gray-600">
        {messages.subtitle}
      </p>
    </>
  );
};
