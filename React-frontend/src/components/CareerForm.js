import React, { useState } from 'react';
import styled from 'styled-components';

const FormContainer = styled.div`
  background-color: #f0f4f8;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  max-width: 600px;
  margin: 2rem auto;
`;

const TextArea = styled.textarea`
  width: 100%;
  padding: 0.5rem;
  margin: 0.5rem 0;
  border: 1px solid #ccc;
  border-radius: 4px;
`;

const Select = styled.select`
  width: 100%;
  padding: 0.5rem;
  margin: 0.5rem 0;
  border: 1px solid #ccc;
  border-radius: 4px;
`;

const Button = styled.button`
  background-color: #0078d4;
  color: white;
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  &:hover {
    background-color: #005bb5;
  }
`;

const CareerForm = ({ onSubmit }) => {
  const [formData, setFormData] = useState({
    skills: '',
    interests: '',
    experience: '',
    experienceLevel: 'EntryLevel', // Default value for experience level
  });

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prevData) => ({
      ...prevData,
      [name]: value,
    }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    onSubmit(formData);
  };

  return (
    <FormContainer>
      <h2>Tell us about yourself</h2>
      <form onSubmit={handleSubmit}>
        <label>
          Skills:
          <TextArea name="skills" value={formData.skills} onChange={handleChange} />
        </label>
        <label>
          Interests:
          <TextArea name="interests" value={formData.interests} onChange={handleChange} />
        </label>
        <label>
          Experience:
          <TextArea name="experience" value={formData.experience} onChange={handleChange} />
        </label>
        <label>
          Experience Level:
          <Select name="experienceLevel" value={formData.experienceLevel} onChange={handleChange}>
            <option value="Internship">Internship</option>
            <option value="EntryLevel">EntryLevel</option>
            <option value="Associate">Associate</option>
            <option value="MidSeniorLevel">MidSeniorLevel</option>
            <option value="Director">Director</option>
          </Select>
        </label>
        <Button type="submit">Get Recommendations</Button>
      </form>
    </FormContainer>
  );
};

export default CareerForm;
