// src/components/Footer.js
import React from 'react';
import styled from 'styled-components';

const FooterContainer = styled.footer`
  background-color: #0078d4;
  color: white;
  padding: 1rem;
  text-align: center;
  position: fixed;
  width: 100%;
  bottom: 0;
`;

const Footer = () => {
  return (
    <FooterContainer>
      <p>© 2024 Cloudblogger - Smart Career Advisor. All rights reserved.</p>
    </FooterContainer>
  );
};

export default Footer;
