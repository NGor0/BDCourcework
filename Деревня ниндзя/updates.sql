
-- хранимые процедуры и триггеры
create or replace function update_villager() returns trigger as
$update_villager$
declare
    ninja_clan_id int;
    clan_name     varchar(64);
begin

    if (new.birthday is null) then
    -- NOTE: default        
        new.birthday := current_date;
    end if;

    if (new.id is null or (select count(*) from ninja where ninja_id = new.id) = cast(1 as bigint)) then
        return new;
    end if;

    select clan_id from ninja where ninja_id = new.id into ninja_clan_id;
    select name from clan where id = ninja_clan_id into clan_name;
    if (ninja_clan_id is not null and new.last_name != clan_name) then
        raise exception 'last name is not equal to ninja clan name';
    end if;

    return new;
end;
$update_villager$ language plpgsql;

create trigger update_villager
    before insert or update
    on villager
    for each row
execute procedure update_villager();

create or replace function after_update_villager() returns trigger as
$after_update_villager$
begin
    if (new.death_date is not null) then
        update ninja set status='DD' where ninja_id = new.id;
        update jinchuuriki set to_date=new.death_date where ninja_id = new.id;
        return null;
    end if;

    return null;
end;
$after_update_villager$ language plpgsql;

create trigger after_update_villager
    after insert or update
    on villager
    for each row
execute procedure after_update_villager();

-- память о создателях кланов и деревень не может быть удалена!
create or replace function check_del_villager() returns trigger as
$check_del_villager$
begin
    if exists(select id from clan where clan.ninja_id = old.id) then
        raise exception 'data about clan founder can not be removed';
    end if;

    if exists(select id from ninja_village where ninja_village.villager_id = old.id) then
        raise exception 'data about clan founder can not be removed';
    end if;
end;
$check_del_villager$ language plpgsql;

CREATE TRIGGER check_del_villager
    BEFORE DELETE
    ON villager
    FOR EACH ROW
EXECUTE PROCEDURE check_del_villager();

create or replace function check_del_ninja() returns trigger as
$check_del_ninja$
begin
    if exists(select id from clan where clan.ninja_id = old.ninja_id) then
        raise exception 'data about clan founder can not be removed';
    end if;

    if exists(select id from ninja_village where ninja_village.villager_id = old.ninja_id) then
        raise exception 'data about clan founder can not be removed';
    end if;
end;
$check_del_ninja$ language plpgsql;

CREATE TRIGGER check_del_ninja
    BEFORE DELETE
    ON ninja
    FOR EACH ROW
EXECUTE PROCEDURE check_del_ninja();

-- вычисляет вохможно ли установить клан у ниндзя
create or replace function is_possible_set_clan_id(ninja_id_ int, clan_id_ int) returns boolean as
$$
declare
    ninja_last_name varchar(64);
    clan_name       varchar(64);
begin
    if (clan_id_ is null) then
        return true;
    end if;
    ninja_last_name := (select last_name from villager where id = ninja_id_);
    clan_name := (select name from clan where id = clan_id_);
    return ninja_last_name = clan_name;
end;
$$ language plpgsql;

-- проверяет ,что значения в нужных диапазонах
create or replace function update_ninja() returns trigger as
$update_ninja$
begin
    if (new.rank not in ('GN', 'CH', 'SN', 'JN', 'KG')) then
        raise exception 'incorrect value for rank';
    elseif (new.status not in ('AC', 'DD', 'RT')) then
        raise exception 'incorrect value for status';
    elseif (not is_possible_set_clan_id(new.ninja_id, new.clan_id)) then
        raise exception 'clan_id can not be set due to difference between clan name and ninja last name';
    end if;

    if (new.rank is null) then
        new.rank := 'GN';
    end if;
    if (new.status is null) then
        new.status := 'AC';
    end if;
    return new;
end;
$update_ninja$ language plpgsql;

create trigger update_ninja
    before insert or update
    on ninja
    for each row
execute procedure update_ninja();

create or replace function update_jinchuuriki() returns trigger as
$update_jinchuuriki$
declare
    death date;
begin
    if (new.from_date is null) then
        new.from_date := current_date;
    end if;
    if exists(select bidju_id
              from jinchuuriki
              where bidju_id = new.bidju_id
                and ((to_date is null and new.to_date > jinchuuriki.from_date) or new.from_date < to_date)) then
        raise exception 'bidju already has jinchuuriki';
    end if;

    if ((select birthday from villager where id = new.ninja_id) > new.from_date) then
        raise exception 'Became jinchuuriki before was born?';
    end if;

    select death_date from villager where id = new.ninja_id into death;

    if (death IS NOT NULL and death < new.from_date) then
        raise exception 'Became jinchuuriki after death?';
    end if;

    return new;
end;
$update_jinchuuriki$ language plpgsql;

create trigger update_jinchuuriki
    before insert or update
    on jinchuuriki
    for each row
execute procedure update_jinchuuriki();


create or replace function update_clan() returns trigger as
$update_clan$
begin
    if ((select v.last_name from villager v where v.id = new.ninja_id) != new.name) then
        raise exception 'clan founder shoud have same last name as clan name';
    end if;

    return new;
end;
$update_clan$ language plpgsql;

create trigger update_clan
    before insert or update
    on clan
    for each row
execute procedure update_clan();

create or replace function update_tech_requirement() returns trigger as
$update_tech_requirement$
declare
    required_tech_id int;
begin
    if exists(select techniq_id
              from technique_requirement
              where techniq_id = new.required_t_id
                and required_t_id = new.techniq_id) then
        raise exception 'cycle in technique requirement';
    end if;

    return new;
end;
$update_tech_requirement$ language plpgsql;

create trigger update_tech_requirement
    before insert or update
    on technique_requirement
    for each row
execute procedure update_tech_requirement();

create or replace function update_skill() returns trigger as
$update_skill$
declare
    required_techn bigint;
    inner_n        bigint;
begin
    select count(*) from technique_requirement where techniq_id = new.techniq_id into required_techn;

    select count(*)
    from skill
             inner join (select required_t_id from technique_requirement where techniq_id = new.techniq_id) as tr
                        on skill.techniq_id = tr.required_t_id
    into inner_n;

    if (required_techn > inner_n) then
        raise exception 'ninja does not some technique(s) required for this technique';
    end if;
    return new;
end;
$update_skill$ language plpgsql;

create trigger update_skill
    before insert or update
    on skill
    for each row
execute procedure update_skill();

-- Запросы update
-- Родиться и стать ниндзя (эта функция находится в data.sql)
select create_villager_ninja('A', 'B', current_date, null, (select id from ninja_village limit 1), null, null, null);
-- Стать джинчуурики в день своего нулегого рождения
insert into jinchuuriki (ninja_id, bidju_id)
values ((select id from villager where first_name = 'A' limit 1), (select id from bidju where name = 'Шукаку'));
--Умереть
update villager
set death_date=current_date
where id = (select id from villager where first_name = 'A' limit 1);
-- Кто-то другой становится джинчуурики биджу из прошлых зaпросов
insert into jinchuuriki (ninja_id, bidju_id)
values ((select id from villager where first_name = 'Саске' limit 1), (select id from bidju where name = 'Шукаку'));
-- Повышение ранга
update ninja
set rank='KG'
where ninja_id = (select id from villager where first_name = 'Наруто' limit 1);

-- Повышение ранга до несуществующего - упадёт
update ninja
set rank='SL'
where ninja_id = (select id from villager where first_name = 'Наруто' limit 1);

--  Наруто не знает Элемент воздуха (упадет)
insert into skill (ninja_id, techniq_id)
values ((select id from villager where first_name = 'Наруто' limit 1),
        (select id from technique where name = 'Большой Шар Расенгана'));

-- Упасть из-за циклической зависимости в техниках
insert into technique_requirement (techniq_id, required_t_id)
values ((select id from technique where name = 'Элемент воздуха'),
        (select id from technique where name = 'Большой Шар Расенгана'));


