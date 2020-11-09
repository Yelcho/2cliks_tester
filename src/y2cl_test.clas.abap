CLASS y2cl_test DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_bsp_application_events .

    DATA: workitem_header TYPE swr_wihdr READ-ONLY,
          alternatives    TYPE STANDARD TABLE OF swr_decialts READ-ONLY,
          email_body      TYPE stringval READ-ONLY,
          error_message   TYPE stringval READ-ONLY.

  PROTECTED SECTION.
  PRIVATE SECTION.

    METHODS get_workitem_details
      IMPORTING
        !workitem_id TYPE swr_struct-workitemid .
ENDCLASS.



CLASS Y2CL_TEST IMPLEMENTATION.


  METHOD get_workitem_details.

    DATA: return_code    TYPE sy-subrc,
          message_lines  TYPE STANDARD TABLE OF swr_messag,
          message_struct TYPE STANDARD TABLE OF swr_mstruc.

    CALL FUNCTION 'SAP_WAPI_GET_HEADER'
      EXPORTING
        workitem_id         = workitem_id
      IMPORTING
        workitem_attributes = workitem_header
        return_code         = return_code
      TABLES
        message_lines       = message_lines
        message_struct      = message_struct.

    IF return_code NE 0.
      error_message = message_lines[ 1 ]-line.
      RETURN.
    ENDIF.

    CALL FUNCTION 'SAP_WAPI_DECISION_READ'
      EXPORTING
        workitem_id  = workitem_id
      TABLES
        alternatives = alternatives.

    IF alternatives IS INITIAL.
      error_message = |There are no decisions for workitem { workitem_id }|.
      RETURN.
    ENDIF.

    DATA: funcname  TYPE rs38l-name,
          functions TYPE STANDARD TABLE OF rfcfunc.

    funcname = 'Z2C_GET_EMAIL_BODY'.

    CALL FUNCTION 'RFC_FUNCTION_SEARCH'
      EXPORTING
        funcname          = funcname
      TABLES
        functions         = functions
      EXCEPTIONS
        nothing_specified = 1
        no_function_found = 2
        OTHERS            = 3.

    IF sy-subrc <> 0.
      funcname = 'Y2C_GET_EMAIL_BODY'.
      CALL FUNCTION 'RFC_FUNCTION_SEARCH'
        EXPORTING
          funcname          = funcname
        TABLES
          functions         = functions
        EXCEPTIONS
          nothing_specified = 1
          no_function_found = 2
          OTHERS            = 3.
      IF sy-subrc <> 0.
        error_message = |Unable top locate GET_EMAIL_BODY RFC-enabled function module|.
        RETURN.
      ENDIF.
    ENDIF.

    CALL FUNCTION funcname
      EXPORTING
        workitem_id = workitem_id
      IMPORTING
        html_data   = email_body.

  ENDMETHOD.


  METHOD if_bsp_application_events~on_request.

    DATA: ffields     TYPE tihttpnvp,
          workitem_id TYPE swr_struct-workitemid.

    TRY.
        request->get_form_fields( CHANGING fields = ffields ).

        get_workitem_details( CONV #( ffields[ name = 'wi' ]-value ) ).

      CATCH cx_sy_itab_line_not_found INTO DATA(cx_itab).
        error_message = |Workitem ID not passed. e.g. http://server.domain.com:1080/sap/bc/bsp/sap/y2cliks_test/default.html?wi=1234 |.

      CATCH cx_root INTO DATA(cx).
        error_message = cx->get_text( ).
    ENDTRY.

  ENDMETHOD.


  METHOD if_bsp_application_events~on_response.
  ENDMETHOD.


  METHOD if_bsp_application_events~on_start.
  ENDMETHOD.


  METHOD if_bsp_application_events~on_stop.
  ENDMETHOD.
ENDCLASS.
