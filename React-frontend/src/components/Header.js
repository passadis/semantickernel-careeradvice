// src/components/Header.js
import React from 'react';
import styled from 'styled-components';
import logo from '../assets/logo.png'; // Ensure this path is correct based on where you place the logo

const HeaderContainer = styled.header`
  background-color: #0078d4;
  color: white;
  padding: 1rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
`;

const Logo = styled.img`
  height: 40px;
  margin-right: 1rem;
`;

const Title = styled.h1`
  margin: 0;
  font-size: 1.5rem;
`;

const Header = () => {
  return (
    <HeaderContainer>
      <div style={{ display: 'flex', alignItems: 'center' }}>
        <Logo src={logo} alt="Logo" />
        <Title>Smart Career Advisor</Title>
      </div>
    </HeaderContainer>
  );
};

export default Header;
