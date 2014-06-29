part of base;

class INTL {

    static January() => Intl.message('January', name:'January');
    static February() => Intl.message('February', name:'February');
    static March() => Intl.message('March', name:'March');
    static April() => Intl.message('April', name:'April');
    static May() => Intl.message('May', name:'May');
    static June() => Intl.message('June', name:'June');
    static July() => Intl.message('July', name:'July');
    static August() => Intl.message('August', name:'August');
    static September() => Intl.message('September', name:'September');
    static October() => Intl.message('October', name:'October');
    static November() => Intl.message('November', name:'November');
    static December() => Intl.message('December', name:'December');

    static Monday() => Intl.message('Monday', name:'Monday');
    static Tuesday() => Intl.message('Tuesday', name:'Tuesday');
    static Wednesday() => Intl.message('Wednesday', name:'Wednesday');
    static Thursday() => Intl.message('Thursday', name:'Thursday');
    static Friday() => Intl.message('Friday', name:'Friday');
    static Saturday() => Intl.message('Saturday', name:'Saturday');
    static Sunday() => Intl.message('Sunday', name:'Sunday');

    static Today() => Intl.message('Today', name:'Today');
    static Yesterday() => Intl.message('Yesterday', name:'Yesterday');
    static One_week_back() => Intl.message('One week back', name:'One_week_back');
    static This_week() => Intl.message('This week', name:'This_week');
    static Last_week() => Intl.message('Last week', name:'Last_week');
    static One_month_back() => Intl.message('One month back', name:'One_month_back');
    static This_month() => Intl.message('This month', name:'This_month');
    static Last_month() => Intl.message('Last month', name:'Last_month');
    static One_year_back() => Intl.message('One year back', name:'One_year_back');
    static This_year() => Intl.message('This year', name:'This_year');
    static Last_year() => Intl.message('Last year', name:'Last_year');
    static All() => Intl.message('All', name:'All');

    static Window() => Intl.message('Window', name:'Window');

    static Choose_period() => Intl.message('- Choose period -', name:'Choose_period');
    static Period() => Intl.message('Period', name:'Period');
    static Group_by() => Intl.message('Group by', name:'Group_by');
    static days() => Intl.message('days', name:'days');
    static months() => Intl.message('months', name:'months');
    static years() => Intl.message('years', name:'years');
    static today() => Intl.message('today', name:'today');
    static empty() => Intl.message('empty', name:'empty');
    static done() => Intl.message('done', name:'done');

    static Yes() => Intl.message('Yes', name:'Yes');
    static No() => Intl.message('No', name:'No');
    static Warning() => Intl.message('Warning', name:'Warning');
    static OK() => Intl.message('OK', name:'OK');

    static Total() => Intl.message('Total', name:'Total');
    static Avarage() => Intl.message('Avarage', name:'Avarage');
    static Maximum() => Intl.message('Maximum', name:'Maximum');
    static Minimum() => Intl.message('Minimum', name:'Minimum');

    static File_manager() => Intl.message('File manager', name:'File_manager');
    static Folders() => Intl.message('Folders', name:'Folders');
    static Move_to() => Intl.message('Move to', name:'Move_to');
    static Add_folder() => Intl.message('Add folder', name:'Add_folder');
    static Edit_folder() => Intl.message('Edit folder', name:'Edit_folder');
    static Move_folder() => Intl.message('Move folder', name:'Move_folder');
    static Delete_folder() => Intl.message('Delete folder', name:'Delete_folder');
    static Add_file() => Intl.message('Add file', name:'Add_file');
    static Delete_file() => Intl.message('Delete file', name:'Delete_file');

    static pages(from, to, total) => Intl.message("current: $from - $to total: $total", name: 'pages', args:[from, to, total]);
}