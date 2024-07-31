import React from 'react';
import styled from 'styled-components';

const RecommendationContainer = styled.div`
  margin: 1rem 0;
  padding: 1rem;
  background-color: #e9ecef;
  border-radius: 4px;
`;

const RecommendationTitle = styled.h4`
  margin: 0;
`;

const RecommendationDescription = styled.p`
  margin: 0.5rem 0 1rem 0;
`;

const Button = styled.button`
  margin-right: 0.5rem;
  padding: 0.5rem 1rem;
  background-color: #007bff;
  color: #fff;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  &:hover {
    background-color: #0056b3;
  }
`;

const Recommendations = ({ recommendations, onFetchJobs, onGenerateSkillingPlan }) => {
  return (
    <div>
      {recommendations.map((recommendation, index) => (
        <RecommendationContainer key={index}>
          <RecommendationTitle>{recommendation.title}</RecommendationTitle>
          <RecommendationDescription>{recommendation.description}</RecommendationDescription>
          <Button onClick={() => onFetchJobs(recommendation.title)}>Job Listings</Button>
          <Button onClick={() => onGenerateSkillingPlan(recommendation.title)}>Skilling Plan</Button>
        </RecommendationContainer>
      ))}
    </div>
  );
};

export default Recommendations;
