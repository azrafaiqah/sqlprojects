USE portfolioproject;

SELECT *
FROM portfolioproject.covid_death
WHERE continent IS NOT NULL
ORDER BY 3,4;

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM portfolioproject.covid_death
ORDER BY location, STR_TO_DATE(date, '%d/%m/%Y');

-- Looking at total cases vs total deaths

SELECT location, date, total_cases, total_deaths, population, (total_deaths/total_cases)*100 AS death_percentage
FROM portfolioproject.covid_death
WHERE location = 'Malaysia'
ORDER BY STR_TO_DATE(date, '%d/%m/%Y');

-- Looking at Total Cases vs Population
-- Shows likelihood of dying if you contract covid in your country
SELECT location, date, population, total_cases, (total_cases/population)*100 AS death_percentage
FROM portfolioproject.covid_death
WHERE location = 'Malaysia'
ORDER BY STR_TO_DATE(date, '%d/%m/%Y');

-- looking at countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) as highest_infection_count, MAX((total_cases/population))*100 AS percent_population_infected
FROM portfolioproject.covid_death
-- WHERE location = 'Malaysia'
GROUP BY location, population
ORDER BY percent_population_infected DESC;

-- looking at countries with highest death count per population

SELECT location, MAX(cast(total_deaths AS SIGNED)) AS total_death_count
FROM portfolioproject.covid_death
-- WHERE location = 'Malaysia'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;

-- LET'S BREAK THINGS DOWN BY CONTINENT

-- showing continents with the highest death count per population

SELECT continent, SUM(new_deaths) AS total_death_count
-- SELECT continent, MAX(cast(total_deaths AS SIGNED)) AS total_death_count
FROM portfolioproject.covid_death
-- WHERE location = 'Malaysia'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC;


-- GLOBAL NUMBERS

SELECT 
	date, 
    SUM(new_cases) AS total_cases, 
    SUM(CAST(new_deaths AS SIGNED)) AS total_deaths, 
    SUM(CAST(new_deaths AS SIGNED))/SUM(new_cases)*100 AS death_percentage
FROM portfolioproject.covid_death
-- WHERE location = 'Malaysia'
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY STR_TO_DATE(date, '%d/%m/%Y'), 2;

-- Looking at Total Population vs Vaccinations

SELECT
	dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM portfolioproject.covid_death dea
JOIN portfolioproject.covid_vaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, STR_TO_DATE(dea.date, '%d/%m/%Y');

-- USE CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS
(
SELECT
	dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM portfolioproject.covid_death dea
JOIN portfolioproject.covid_vaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- ORDER BY 2, STR_TO_DATE(dea.date, '%d/%m/%Y')
)
SELECT *, (rolling_people_vaccinated/population)*100
FROM PopvsVac;

-- TEMP TABLE

DROP TABLE IF EXISTS percent_population_vaccinated;
CREATE TABLE percent_population_vaccinated
(
continent VARCHAR(255) CHARSET utf8,
location VARCHAR(255) CHARSET utf8,
date text,
population INT(255),
new_vaccinations INT(255),
rolling_people_vaccinated INT(255)
)
ENGINE=INNODB;
INSERT INTO percent_population_vaccinated
SELECT
	dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM portfolioproject.covid_death dea
JOIN portfolioproject.covid_vaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
-- ORDER BY 2, STR_TO_DATE(dea.date, '%d/%m/%Y')

SELECT *, (rolling_people_vaccinated/population)*100
FROM percent_population_vaccinated;

-- Creating view to store data for later visualization

CREATE VIEW percent_population_vaccinated AS
SELECT
	dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM portfolioproject.covid_death dea
JOIN portfolioproject.covid_vaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
-- ORDER BY 2, STR_TO_DATE(dea.date, '%d/%m/%Y')


SELECT *
FROM percent_population_vaccinated