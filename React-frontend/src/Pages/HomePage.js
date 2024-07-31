import React, { useState, useEffect } from 'react';
import CareerForm from '../components/CareerForm';
import Recommendations from '../components/Recommendations';
import axios from 'axios';
import styled from 'styled-components';

const Container = styled.div`
  padding: 2rem;
  background-color: #f9f9f9;
  padding-bottom: 4rem; /* Ensure content doesn't hide behind footer */
`;

const ErrorText = styled.p`
  color: red;
`;

const JobListingsContainer = styled.div`
  margin-top: 2rem;
`;

const JobList = styled.ul`
  list-style-type: none;
  padding: 0;
`;

const JobListItem = styled.li`
  background-color: #fff;
  padding: 1rem;
  margin: 0.5rem 0;
  border: 1px solid #ddd;
  border-radius: 4px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
`;

const JobLink = styled.a`
  color: #0078d4;
  text-decoration: none;
  &:hover {
    text-decoration: underline;
  }
`;

const LoadingMessage = styled.div`
  margin-top: 2rem;
  text-align: center;
  font-size: 1.2rem;
`;

const SkillingPlanContainer = styled.div`
  margin-top: 2rem;
`;

const HomePage = () => {
  const [recommendations, setRecommendations] = useState([]);
  const [error, setError] = useState(null);
  const [jobs, setJobs] = useState([]);
  const [formData, setFormData] = useState({});
  const [loadingRecommendations, setLoadingRecommendations] = useState(false);
  const [loadingJobs, setLoadingJobs] = useState(false);
  const [loadingSkillingPlan, setLoadingSkillingPlan] = useState(false);
  const [skillingPlan, setSkillingPlan] = useState(null);

  const handleFormSubmit = async (formData) => {
    setFormData(formData);
    setLoadingRecommendations(true);
    setError(null); // Clear error on new interaction
    try {
      const response = await fetch(`${process.env.REACT_APP_API_URL}/get-recommendations`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(formData),
      });
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const data = await response.json();
      if (data.error) {
        throw new Error(data.error);
      }
      setRecommendations(data.recommendations || []);
    } catch (error) {
      console.error('Error fetching recommendations:', error);
      setError(error.message);
      setRecommendations([]);
    } finally {
      setLoadingRecommendations(false);
    }
  };

  const fetchJobs = async (title) => {
    setLoadingJobs(true);
    setError(null); // Clear error on new interaction
    try {
      const requestPayload = {
        title: title,
        location: "anywhere",
        rows: 5,
        workType: "Hybrid",
        contractType: "FullTime",
        experienceLevel: formData.experienceLevel,
        companyNames: [],
        publishedAt: "PastMonth"
      };

      const response = await axios.post(`${process.env.REACT_APP_API_URL}/fetch-jobs`, requestPayload);
      if (response.data.jobs.length === 0) {
        throw new Error("No job listings found");
      }
      setJobs(response.data.jobs);
    } catch (error) {
      console.error('Error fetching jobs:', error);
      setError("No job listings found");
      setJobs([]);
    } finally {
      setLoadingJobs(false);
    }
  };

  const generateSkillingPlan = async (title) => {
    setLoadingSkillingPlan(true);
    setError(null); // Clear error on new interaction
    try {
      const requestPayload = {
        UserSelection: title,
        Skills: formData.skills,
        Interests: formData.interests,
        Experience: formData.experience,
      };

      const response = await axios.post(`${process.env.REACT_APP_API_URL}/skilling-plan`, requestPayload);
      setSkillingPlan(response.data.skillingPlan);
    } catch (error) {
      console.error('Error generating skilling plan:', error);
      setError(error.message);
    } finally {
      setLoadingSkillingPlan(false);
    }
  };

  const isLoading = loadingRecommendations || loadingJobs || loadingSkillingPlan;

  // Optional: Automatically hide error message after 5 seconds
  useEffect(() => {
    if (error) {
      const timer = setTimeout(() => setError(null), 5000);
      return () => clearTimeout(timer);
    }
  }, [error]);

  return (
    <Container>
      <CareerForm onSubmit={handleFormSubmit} />
      {error && <ErrorText>{error}</ErrorText>}
      {isLoading && <LoadingMessage>Loading, please wait...</LoadingMessage>}
      {!isLoading && recommendations.length > 0 && (
        <Recommendations
          recommendations={recommendations}
          onFetchJobs={fetchJobs}
          onGenerateSkillingPlan={generateSkillingPlan}
        />
      )}
      {!isLoading && jobs.length > 0 && (
        <JobListingsContainer>
          <h3>Job Listings</h3>
          <JobList>
            {jobs.map((job, index) => (
              <JobListItem key={index}>
                <JobLink href={job.jobUrl} target="_blank" rel="noopener noreferrer">
                  {job.title}
                </JobLink>: {job.description}
              </JobListItem>
            ))}
          </JobList>
        </JobListingsContainer>
      )}
      {skillingPlan && (
        <SkillingPlanContainer>
          <h3>Skilling Plan</h3>
          <p>{skillingPlan}</p>
        </SkillingPlanContainer>
      )}
    </Container>
  );
};

export default HomePage;
