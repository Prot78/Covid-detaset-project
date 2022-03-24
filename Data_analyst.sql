/* After downloading a dataset inclusive of Covid information. the following was made to achieve a covid death rate upcome */

create table if not exists public.covid_death (
	ID_covid integer unique
	, iso_code text
	, continent text
	, location_covid text
	, date_covid date
	, population double precision
	, total_cases double precision
	, new_cases integer
	, new_cases_smoothed double precision
	, total_deaths double precision
	, new_deaths integer
	, new_deaths_smoothed double precision
	, total_cases_per_million double precision
	, new_cases_per_million double precision
	, new_cases_smoothed_per_million double precision
	, total_deaths_per_million double precision
	, new_deaths_per_million double precision
	, new_deaths_smoothed_per_million double precision
	, reproduction_rate double precision
	, icu_patients integer,
	icu_patients_per_million double precision
	, hosp_patients integer
	, hosp_patients_per_million double precision
	, weekly_icu_admissions integer
	, weekly_icu_admissions_per_million double precision
	, weekly_hosp_admissions integer
	, weekly_hosp_admissions_per_million double precision
);



create table if not exists public.covid_vaccinations (
	ID_covid integer references covid_death(ID_covid)
	, iso_code text
	, continent text
	, location_covid text
	, date_covid date
	,population double precision
	, new_tests integer
	,total_tests integer
	,total_tests_per_thousand double precision
	,new_tests_per_thousand double precision
	,new_tests_smoothed double precision
	,new_tests_smoothed_per_thousand double precision
	,positive_rate double precision
	,tests_per_case double precision
	,tests_units text
	,total_vaccinations double precision
	,people_vaccinated double precision
	,people_fully_vaccinated double precision
	,total_boosters double precision
	,new_vaccinations double precision
	,new_vaccinations_smoothed double precision
	,total_vaccinations_per_hundred double precision
	,people_vaccinated_per_hundred double precision
	,people_fully_vaccinated_per_hundred double precision
	,total_boosters_per_hundred double precision
	,new_vaccinations_smoothed_per_million double precision
	,new_people_vaccinated_smoothed double precision
	,new_people_vaccinated_smoothed_per_hundred double precision
	,stringency_index double precision
	,population_density double precision
	,median_age double precision
	,aged_65_older double precision
	,aged_70_older double precision
	,gdp_per_capita double precision
	,extreme_poverty double precision
	,cardiovasc_death_rate double precision
	,diabetes_prevalence double precision
	,female_smokers double precision
	,male_smokers double precision
	,handwashing_facilities double precision
	,hospital_beds_per_thousand double precision
	,life_expectancy double precision
	,human_development_index double precision
	,excess_mortality_cumulative_absolute double precision
	,excess_mortality_cumulative double precision
	,excess_mortality double precision
	,excess_mortality_cumulative_per_million double precision
);

drop table covid_death; 
drop table covid_vaccinations;

select *
from covid_death;


--Global cases
with cte as(
	select (cast(sum(new_cases) as double precision)) as total_cases
		, sum((new_deaths)) as total_death
		, max(population) as world_population
	from covid_death
)
select cte.total_cases
	, cte.total_death
	,cast (((cte.total_death/cte.world_population)*100) as DECIMAL(16, 6)) as world_death_percentage
	, cast (((cte.total_death/cte.total_cases)*100) as DECIMAL(16, 6)) avg_death_population
from cte

 
/*  Total Death for each continent  */

select distinct continent
	, sum((new_deaths)) as total_death_count
from covid_death
where continent is not null
group by continent


/* Total death_rate by country  */
with cte as (
	select distinct location_covid
		, population
		, sum((new_deaths)) as death_rate_by_country
	from covid_death
	where location_covid is not null
	group by location_covid, population
)
select cte.location_covid
	, cast((cte.death_rate_by_country/cte.population)*100 as DECIMAL(6, 5)) as death_rate_by_country
from cte
order by 1


/* death percentage over time  */
with cte as (
	select distinct location_covid
		, population
		, date_covid
		, sum(total_deaths) as death_rate
	from covid_death
	where 
		location_covid is not null 
		--location_covid like '%Ita%'    /* you can insert these lines if needed */
		 --or location_covid like '%State%'
	group by location_covid, population, date_covid
	order by 1,3
)
select cte.location_covid
	, cte.date_covid
	, sum((cte.death_rate/cte.population)*100) 
		over (partition by cte.location_covid, cte.date_covid order by cte.date_covid) as death_rate_by_country
from cte
order by 1


select location_covid, total_deaths
from covid_death;



-- Total cases vs total death percentage
-- Shows likelihood of getting infected
select location_covid
	, date_covid
	, total_cases
	, total_deaths
	, cast(((total_deaths/total_cases)*100)as DECIMAL(16, 2)) as death_percentage
	, cast(((total_cases/population)*100)as DECIMAL(16, 2)) as populatioin_infected_percentage
	 --, max(total_cases) as covid_total_cases
	--, count(total_deaths) as covid_total_deaths
from covid_death
where location_covid like '%Sta%'
--group by location_covid, (total_deaths/total_cases)*100
order by location_covid;
--order by count(total_cases) desc;


--Which country has the highest infection rate
select location_covid
	, population
	, max(cast(((total_cases/population)*100)as DECIMAL(16, 2))) as country_with_highest_infectionrate
from covid_death
where continent is not null 
	--and max(cast(((total_cases/population)*100)as DECIMAL(16, 2))) > 0
group by location_covid, population
order by max(cast(((total_cases/population)*100)as DECIMAL(16, 2))) desc


--Which continent has the highest death rate
select location_covid
	, population
	, max(cast(((total_deaths/total_cases)*100)as DECIMAL(16, 2))) as continent_with_highest_deathrate
	, max(total_deaths) as continent_highest_death
from covid_death
where continent is null 
	--and max(cast(((total_cases/population)*100)as DECIMAL(16, 2))) > 0
group by location_covid, population
order by continent_highest_death desc;









/* ****************************************************************** */


/* Percentage vaccination rate for each nation each day */
with cte as(
	select dea.continent
		, dea.location_covid
		, dea.date_covid
		, sum(vac.new_vaccinations/dea.population*100) 
			over (partition by dea.location_covid ,dea.date_covid order by dea.date_covid) as perc_vaccinated
	from covid_death as dea
		join covid_vaccinations as vac
		on dea.ID_covid = vac.ID_covid
	where dea.continent = 'Europe'
	order by 1
)
select distinct cte.location_covid
	, cte.date_covid
	, round(cte.perc_vaccinated) as perc_vaccinated
from cte
where cte.perc_vaccinated is not null
order by 1,2




/* Maximum percentage vaccination rate for each nation */
with cte as (
	select dea.continent
			, dea.population
			, dea.location_covid
			, dea.date_covid
			, vac.new_vaccinations
			, sum(vac.new_vaccinations/dea.population*100) 
				over (partition by dea.location_covid ,dea.date_covid order by dea.date_covid) as perc_vaccinated
		from covid_death as dea
			join covid_vaccinations as vac
			on dea.ID_covid = vac.ID_covid
		where dea.continent = 'Europe'
		order by 1
)
select distinct cte.location_covid
	, cte.continent
	, cte.population
	, sum(cte.new_vaccinations) over (partition by cte.location_covid) as vac_total_number
	, round(sum(cte.perc_vaccinated) over (partition by cte.location_covid)) as new_vac_perc
from cte 
order by 1  


/****************  */
/*     CREATE VIEW    */
create view PercentagePopulationVaccinated as 
with cte as (
	select dea.continent
			, dea.population
			, dea.location_covid
			, dea.date_covid
			, vac.new_vaccinations
			, sum(vac.new_vaccinations/dea.population*100) 
				over (partition by dea.location_covid ,dea.date_covid order by dea.date_covid) as perc_vaccinated
		from covid_death as dea
			join covid_vaccinations as vac
			on dea.ID_covid = vac.ID_covid
		where dea.continent = 'Europe'
		order by 1
)
select distinct cte.location_covid
	, cte.continent
	, cte.population
	, sum(cte.new_vaccinations) over (partition by cte.location_covid) as vac_total_number
	, round(sum(cte.perc_vaccinated) over (partition by cte.location_covid)) as new_vac_perc
from cte 
order by 1  


/*  TIME  Year   */
select dea.location_covid
	, dea.date_covid
	, date_part('year', dea.date_covid) as "Today''s Year"
	, date_trunc('year', dea.date_covid) as "Trunc Year"
from covid_death as dea


/*  Estimate how many total number of vaccine and new vaccine in percentage have been made for each country every year */
with cte as (
	select dea.continent
			, dea.population
			, dea.location_covid
			, dea.date_covid
			, date_part('year', dea.date_covid) as covid_Year
			, vac.new_vaccinations
			, sum(vac.new_vaccinations/dea.population*100) 
				over (partition by dea.location_covid ,dea.date_covid order by dea.date_covid) as perc_vaccinated
		from covid_death as dea
			join covid_vaccinations as vac
			on dea.ID_covid = vac.ID_covid
		where dea.continent = 'Europe'
		order by 1
)
select distinct cte.location_covid
	, cte.continent
	, cte.population
	, cte.covid_Year
	, sum(cte.new_vaccinations) over (partition by cte.covid_Year, cte.location_covid) as vac_total_number
	, round(sum(cte.perc_vaccinated) over (partition by cte.covid_Year, cte.location_covid)) as new_vac_perc
from cte 
order by 1 



