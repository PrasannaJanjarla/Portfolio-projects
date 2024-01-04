select *
from Portfolioproject..Coviddeaths
order by 3,4


--select *
--from Portfolioproject..CovidVaccinations
--order by 3,4\

Select Location,date,total_cases,new_cases,total_deaths,population_density
from Portfolioproject..Coviddeaths
order by 1,2

--looking at total cases Vs total deaths
-- shows the probability of death if one gets in contact with covid

Select location, date, total_cases,total_deaths, 
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Deathpercentage
from PortfolioProject..covidDeaths
where location like '%India%'
order by 1,2


--looking at total cases Vs population_density
--depicts the percentage of population got covid

Select location, date, total_cases,population_density, 
(CONVERT(float, population_density) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Infectedpeoplepercentage
from PortfolioProject..covidDeaths
order by 1,2

--searching for countries with highest infection compared to population
--Select location, MAX(total_cases) as Highestinfectedcount,population_density, 
--MAX((total_cases/population_density))*100 as  HIGHESTInfectedpeoplepercentage
----MAX((CONVERT(float, population_density) / NULLIF(CONVERT(float, total_cases), 0))) * 100 AS HIGHESTInfectedpeoplepercentage

--from PortfolioProject..covidDeaths
--Group by location,population_density
--order by HIGHESTInfectedpeoplepercentage desc

SELECT
  location,
  MAX(CAST(total_cases AS INT)) as HighestInfectedCount,
  MAX(CAST(population_density AS FLOAT)) as population_density,
  MAX(CAST(total_cases AS FLOAT) / NULLIF(CAST(population_density AS FLOAT), 0)) * 100 as HighestInfectedPeoplePercentage
FROM
  PortfolioProject..covidDeaths
WHERE
  CAST(population_density AS FLOAT) > 0  -- Exclude rows with population_density = 0
GROUP BY
  location
ORDER BY
  HighestInfectedPeoplePercentage DESC;


--showing countries with highest death count per population

Select location, MAX(total_deaths) as totaldeathcount 
from PortfolioProject..covidDeaths
where continent is not null
group by location
order by totaldeathcount desc

-- lets explore by dividing the things according to continent

Select location, MAX(total_deaths) as totaldeathcount 
from PortfolioProject..covidDeaths
where continent IS not NULL AND continent <> ''
group by location
order by totaldeathcount desc

-- 
select continent,  sum(cast(total_deaths as int)) as totaldeaths
from PortfolioProject..covidDeaths
where continent!=''
group by continent
order by totaldeaths desc


--Total population Vs vaccinations

select dea.continent,dea.location,dea.date,dea.population_density,vac.new_vaccinations,SUM(CONVERT(bigint,vac.new_vaccinations))OVER(partition by dea.location order by dea.location,dea.date)
from PortfolioProject..covidDeaths dea
join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date=vac.date
where dea.continent!=''
and vac.new_vaccinations!=''
order by 1,2,3


-- USE CTE/TEMP TABLE

WITH popvsvac (continent, location, date, population_density, new_vaccinations, rollingpeoplevaccinated)
AS
(
    SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population_density,
        vac.new_vaccinations,
        SUM(ISNULL(CONVERT(FLOAT, vac.new_vaccinations), 0)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rollingpeoplevaccinated
    FROM
        PortfolioProject..covidDeaths dea
    JOIN
        PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
    WHERE
        dea.continent != ''
        AND vac.new_vaccinations != ''
)
SELECT
    *,
    CASE
        WHEN ISNUMERIC(rollingpeoplevaccinated) = 1 AND ISNUMERIC(population_density) = 1 AND CONVERT(FLOAT, population_density) <> 0
        THEN (CONVERT(FLOAT, rollingpeoplevaccinated) / CONVERT(FLOAT, population_density)) * 100
        ELSE NULL
    END AS VaccinationPercentage
FROM
    popvsvac;



--creating temp table

CREATE TABLE #vaccinationpercentagetable
(
    continent nvarchar(255),
    location nvarchar(255),
    date datetime,
    population_density nvarchar(max),  -- Adjust the length to fit your data
    new_vaccinations numeric,
    rollingpeoplevaccinated numeric
);

INSERT INTO #vaccinationpercentagetable
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population_density,
    vac.new_vaccinations,
    SUM(ISNULL(CONVERT(FLOAT, vac.new_vaccinations), 0)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rollingpeoplevaccinated
FROM
    PortfolioProject..covidDeaths dea
JOIN
    PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    dea.continent != ''
    AND vac.new_vaccinations != '';

SELECT
    *,
    CASE
        WHEN ISNUMERIC(rollingpeoplevaccinated) = 1 AND ISNUMERIC(population_density) = 1 AND CONVERT(FLOAT, population_density) <> 0
        THEN (CONVERT(FLOAT, rollingpeoplevaccinated) / CONVERT(FLOAT, population_density)) * 100
        ELSE NULL
    END AS VaccinationPercentage
FROM #vaccinationpercentagetable



--creating view to store data for later use

CREATE VIEW vaccinationpercentagetable AS
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population_density,
    CAST(vac.new_vaccinations AS numeric) AS new_vaccinations,
    CAST(SUM(ISNULL(CAST(vac.new_vaccinations AS FLOAT), 0)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS numeric) AS rollingpeoplevaccinated
FROM
    PortfolioProject..covidDeaths dea
JOIN
    PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
    dea.continent != ''
    AND vac.new_vaccinations != '';
GO

USE PortfolioProject; -- Replace YourDatabaseName with the actual database name
GO


select * from vaccinationpercentagetable









