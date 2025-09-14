import React from 'react';
import { Container, Text, Click } from '..';

const Accounting: React.FC = () => {
  // Contractor management component
  return (
    <>
      <Container tag='nav'>
        <Click tag='button' children={<Text tag='p'>Kalkulator Podatkowy</Text>} />
      </Container>
      <Container tag='header'></Container>
      <Container tag='main'></Container>

      <Container tag='footer'>
        <Container tag='div'>
          <Container tag='div'>
            <Text tag='p'>
              © 2025 ChainRice Tax System. Wszystkie prawa zastrzeżone.
            </Text>
            <Text tag='p'>
              Zintegrowany z blockchain Cosmos SDK | Port API: 8003 | Port
              Blockchain: 1317
            </Text>
          </Container>
        </Container>
      </Container>
    </>
  );
};

export default Accounting;
