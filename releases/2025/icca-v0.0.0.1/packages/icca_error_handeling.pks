create or replace package icca_error_handeling 
is

    function f_error_handling(p_error in apex_error.t_error)
    return apex_error.t_error_result;

end icca_error_handeling;
/