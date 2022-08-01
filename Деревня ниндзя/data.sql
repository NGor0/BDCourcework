-- просто вспомогательная функция для заполнения данными
create or replace function create_villager_ninja(first_name_ varchar(64), last_name_ varchar(64), birthday_ date,
                                                 death_date_ date, village_id_ int, status_ varchar(2),
                                                 rank_ varchar(2), clan_id_ int) returns int as
$$
declare
    vil_id int;
begin
    insert into villager (first_name, last_name, birthday, death_date, village_id)
    values (first_name_, last_name_, birthday_, death_date_, village_id_)
    returning id into vil_id;

    insert into ninja (ninja_id, status, rank, clan_id) values (vil_id, status_, rank_, clan_id_);

    return vil_id;
end;
$$ language plpgsql;

begin transaction;

set constraints all deferred;

insert into villager (first_name, last_name, birthday, death_date, village_id)
values ('Хаширама', 'Сенджу', '1910-10-12', '1955-02-19', 0);

insert into ninja (ninja_id, rank, status)
values (currval('villager_id_seq'), 'KG', 'DD');

insert into clan (name, description, ninja_id)
values ('Сенджу',
        'Один из кланов, ответственных за создание Деревни Скрытого Листа – первой скрытой деревни в истории',
        currval('villager_id_seq'));

insert
into ninja_village (name, description, foundation_date, villager_id)
values ('Коноха',
        'Деревня скрытого листа. Деревня имеет огромные размеры, но в манге и аниме показываются только несколько улиц. Позднее деревня была значительно увеличена и приобрела вид крупного города. Главной достопримечательностью Скрытого Листа являются вырезанные на горе лица Хокаге. Ранее уровень развития инфраструктуры и технологий в деревне был незначителен, однако позже мы можем наблюдать, как Шестой и Седьмой Хокаге пользуются ноутбуками в кабинете, из чего можно сделать вывод, что деревня совершила научно-техническую революцию. Название деревни придумал Мадара Учиха.',
        '1950-04-01', currval('villager_id_seq'));

update villager
set village_id=currval('ninja_village_id_seq')
where id = currval('villager_id_seq');

update ninja
set clan_id=currval('clan_id_seq')
where ninja_id = currval('villager_id_seq');

insert into villager(first_name, last_name, birthday, village_id)
values ('Простой', 'Смертный', '2000-12-12', currval('ninja_village_id_seq'));

select create_villager_ninja('Тобирама', 'Сенджу', '1915-04-03', '1958-07-12', currval('ninja_village_id_seq')::int,
                             'DD', 'KG',
                             currval('clan_id_seq')::int);
select create_villager_ninja('Наруто', 'Узумаки', '1990-12-23', null, currval('ninja_village_id_seq')::int, 'AC', 'JN',
                             null);
select create_villager_ninja('Сакура', 'Харуно', '1990-05-17', null, currval('ninja_village_id_seq')::int, 'AC', 'JN',
                             null);
select create_villager_ninja('Саске', 'Учиха', '1990-11-11', null, currval('ninja_village_id_seq')::int, 'AC', 'JN',
                             null);
select create_villager_ninja('Кушина', 'Узумаки', '1970-02-23', '1990-12-23', currval('ninja_village_id_seq')::int,
                             'DD', 'JN', null);

insert into villager (first_name, last_name, birthday, death_date, village_id)
values ('Zakhar', 'Опоссумской', '1999-07-12', null, 0);

insert into ninja (ninja_id, rank, status)
values (currval('villager_id_seq'), 'KG', 'AC');

insert into clan (name, description, ninja_id)
values ('Опоссумской',
        'Самый мусорный и бесстрашный клан',
        currval('villager_id_seq'));

insert
into ninja_village (name, description, foundation_date, villager_id)
values ('Ахонок',
        'Деревня скрытая в мусоре',
        '1488-04-01', currval('villager_id_seq'));

update villager
set village_id=currval('ninja_village_id_seq')
where id = currval('villager_id_seq');

select create_villager_ninja('Диана', 'Кудайбердиева', '1999-01-24', null, currval('ninja_village_id_seq')::int, 'AC',
                             'JN', null);

insert into bidju (name, tails_amount, description)
values ('Опоссум', '2', 'Великий и ужасный, восхваляющий Сатану и мусор');

insert into jinchuuriki (ninja_id, bidju_id, from_date, to_date)
values (currval('villager_id_seq'), currval('bidju_id_seq'), '1999-01-24', null);

commit transaction;


begin transaction;
-- биджу и джинчуурики
insert into bidju (name, tails_amount, description)
values ('Курама', 9,
        'Курама — кицунэ с девятью длинными хвостами. Шерсть у него красно-оранжевая, а вокруг глаз и до ушей — черная. Радужки красные, а зрачки черные. Верхняя часть туловища подобна человеческой, имеются даже большие пальцы на лапах. В последние дни Хагоромо Ооцуцуки Курама был гораздо меньшим в размерах, но все равно превосходил своего творца. Внешне он казался мягче, форма лица сперва не была заостренной на манер лисицы.'),
       ('Шукаку', 1,
        'Шукаку больше напоминает огромного существа похожего на собака-енота с синими полосками на руках и спине. Шукаку однохвостый обладал огромной силой и чакрой ветра.');

insert into jinchuuriki (ninja_id, bidju_id, from_date, to_date)
values ((select id from villager where first_name = 'Наруто' limit 1), (select id from bidju where name = 'Курама'),
        '1990-12-23', null),
       ((select id from villager where first_name = 'Кушина' limit 1), (select id from bidju where name = 'Курама'),
        '1979-04-03', '1990-12-23');

-- техники
insert into technique (name)
values ('Элемент воды'),
       ('Элемент воздуха'),
       ('Расенган'),
       ('Большой Шар Расенгана'),
       ('Теневое клонирование'),
       ('Шаринган'),
       ('Манекье Шаринган'),
       ('Аматерасу');

insert into technique_requirement(techniq_id, required_t_id)
values ((select id from technique where name = 'Расенган'), (select id from technique where name = 'Элемент воздуха')),
       ((select id from technique where name = 'Большой Шар Расенгана'),
        (select id from technique where name = 'Расенган')),
       ((select id from technique where name = 'Манекье Шаринган'), (select id from technique where name = 'Шаринган')),
       ((select id from technique where name = 'Аматерасу'),
        (select id from technique where name = 'Манекье Шаринган'));

commit transaction;


