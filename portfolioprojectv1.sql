--select * 
--From PortfolioProject..CovidDeaths
--order by 3,4

--select * 
--From PortfolioProject..CovidVaccinations
--order by 3,4

-- Select Data that we are going to be using

Select Location, date, total_cases, new_cases, total_deaths, population 
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2


-- Looking at total cases vs total deaths 
-- Likelihood of dying if you contract covid in your country

Select date, total_cases, total_deaths, 
cast((total_deaths/total_cases)*100 as numeric(10,2)) as DeathPercentage
from PortfolioProject..CovidDeaths
Where location like '%states%' 
AND total_cases is not null
order by 1,2


--Looking at Total Cases vs Population 
--Percentage of population which has contracted COVID

Select Location, date, total_cases, Population, 
cast((total_cases/population)*100 as numeric(10,2)) as InfectedPercentage
from PortfolioProject..CovidDeaths
--Where location like '%states%'
order by InfectedPercentage desc

-- Looking at countries with highest Infection rate compared to popuation

Select Location, Population, MAX(total_cases) as HighestInfectionCount, MAX(  
cast((total_cases/population)*100 as numeric(10,2))) as PopulationInfectedPercentage
from PortfolioProject..CovidDeaths
Where location like '%states%'
Group by Location, Population
order by PopulationInfectedPercentage desc

-- Showing Countries with Highest Death Count per Population 

select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
where continent is not null
Group by Location 
order by TotalDeathCount desc

select Location, MAX(cast(total_deaths as int)) as 'Total Death Count'
From PortfolioProject..CovidDeaths
where continent is null
Group by Location 
order by 'Total Death Count' asc

-- GLOBAL NUMBERS

select date, SUM(new_cases) as 'Cases'
from PortfolioProject..CovidDeaths
where continent is not null
group by date
order by 1,2

-- BY CONTINENT 

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount 
From PortfolioProject..CovidDeaths 
Where continent is not null 
Group by continent 
order by TotalDeathCount desc

-- by location but includes things like class placement 
Select location, MAX(cast(Total_deaths as int)) as TotalDeathCount 
From PortfolioProject..CovidDeaths 
Where continent is null 
Group by location 
order by TotalDeathCount desc


-- Showing continents with Highest death count 

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount 
From PortfolioProject..CovidDeaths 
Where continent is not null 
Group by continent 
order by TotalDeathCount desc

-- GLOBAL 45:30 in video. must use aggregate functions if using multiple columns and group by

Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
cast((SUM(cast(new_deaths as int))/SUM(new_cases))*100 as numeric(10,2)) as DeathPercentage
from PortfolioProject..CovidDeaths 
where continent is not null
Group by date 
order by DeathPercentage desc

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
cast((SUM(cast(new_deaths as int))/SUM(new_cases))*100 as numeric(10,2)) as DeathPercentage
from PortfolioProject..CovidDeaths 
where continent is not null
--Group by date 
order by 1,2

-- Looking at Total Population vs Vaccinations
--JOIN TABLES
--PARTITION

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) 
AS Rolling_People_Vaccinated
, (
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent is not null AND new_vaccinations is not null
ORDER BY 2,3

--USE CTE

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, Rolling_People_Vaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) 
AS Rolling_People_Vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent is not null 
--ORDER BY 2,3
)
Select *, (Rolling_People_Vaccinated/Population)*100
From PopvsVac

--TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime, 
Population numeric,
New_Vaccinations numeric, 
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) 
AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent is not null 

Select *, (RollingPeopleVaccinated/Population)*100 
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualizations 
drop table #PercentPopulationVaccinated
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) 
  AS Rolling_People_Vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent is not null 
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated