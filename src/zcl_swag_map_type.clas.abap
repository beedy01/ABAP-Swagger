CLASS zcl_swag_map_type DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS map
      IMPORTING
        !is_parm       TYPE seosubcodf
      RETURNING
        VALUE(rv_type) TYPE string .
    METHODS map_internal
      IMPORTING
        !io_typedescr  TYPE REF TO cl_abap_typedescr
      RETURNING
        VALUE(rv_type) TYPE string .
    METHODS map_structure
      IMPORTING
        !io_typedescr  TYPE REF TO cl_abap_typedescr
      RETURNING
        VALUE(rv_type) TYPE string .
    METHODS map_table
      IMPORTING
        !io_typedescr  TYPE REF TO cl_abap_typedescr
      RETURNING
        VALUE(rv_type) TYPE string .
    METHODS map_element
      IMPORTING
        !io_typedescr  TYPE REF TO cl_abap_typedescr
      RETURNING
        VALUE(rv_type) TYPE string .
    CLASS-METHODS get_typedescr
      IMPORTING
        !is_parm            TYPE seosubcodf
      RETURNING
        VALUE(ro_typedescr) TYPE REF TO cl_abap_typedescr .
ENDCLASS.



CLASS ZCL_SWAG_MAP_TYPE IMPLEMENTATION.


  METHOD get_typedescr.

    DATA: lv_name TYPE string.


    cl_abap_typedescr=>describe_by_name(
      EXPORTING
        p_name         = is_parm-type
      RECEIVING
        p_descr_ref    = ro_typedescr
      EXCEPTIONS
        type_not_found = 1
        OTHERS         = 2 ).
    IF sy-subrc <> 0.
* try looking in the class
      ASSERT NOT is_parm-clsname IS INITIAL.
      CONCATENATE
        '\CLASS=' is_parm-clsname
        '\TYPE=' is_parm-type
        INTO lv_name.
      ro_typedescr = cl_abap_typedescr=>describe_by_name( lv_name ).
    ENDIF.

  ENDMETHOD.                    "get_typedescr


  METHOD map.
    rv_type = map_internal( get_typedescr( is_parm ) ).
  ENDMETHOD.                    "map


  METHOD map_element.

    CASE io_typedescr->type_kind.
      WHEN cl_abap_typedescr=>typekind_string
          OR cl_abap_typedescr=>typekind_char
          OR cl_abap_typedescr=>typekind_date
          OR cl_abap_typedescr=>typekind_time
          OR cl_abap_typedescr=>typekind_num
          OR cl_abap_typedescr=>typekind_hex.
        rv_type = '"type":"string"'.
      WHEN cl_abap_typedescr=>typekind_int1
          OR cl_abap_typedescr=>typekind_int.
        rv_type = '"type":"integer"'.
      WHEN cl_abap_typedescr=>typekind_xstring.
        rv_type = '"type":"binary"'.
      WHEN OTHERS.
        ASSERT 0 = 1.
    ENDCASE.

  ENDMETHOD.                    "map_element


  METHOD map_internal.

    CASE io_typedescr->kind.
      WHEN cl_abap_typedescr=>kind_elem.
        rv_type = map_element( io_typedescr ).
      WHEN cl_abap_typedescr=>kind_struct.
        rv_type = map_structure( io_typedescr ).
      WHEN cl_abap_typedescr=>kind_table.
        rv_type = map_table( io_typedescr ).
      WHEN OTHERS.
        ASSERT 0 = 1.
    ENDCASE.

  ENDMETHOD.                    "map_internal


  METHOD map_structure.

    DATA: lv_index      TYPE i,
          lv_type       TYPE string,
          lt_components TYPE cl_abap_structdescr=>component_table,
          lo_struct     TYPE REF TO cl_abap_structdescr.

    FIELD-SYMBOLS: <ls_component> LIKE LINE OF lt_components.


    lo_struct ?= io_typedescr.
    lt_components = lo_struct->get_components( ).

* todo, this only works with 1 level
    LOOP AT lt_components ASSIGNING <ls_component> WHERE as_include = abap_true.
      lo_struct ?= <ls_component>-type.
      APPEND LINES OF lo_struct->get_components( ) TO lt_components.
    ENDLOOP.
    DELETE lt_components WHERE as_include = abap_true.

    rv_type = '"schema":{"type":"object", "properties":{'.

    LOOP AT lt_components ASSIGNING <ls_component>.
      lv_index = sy-tabix.

      ASSERT NOT <ls_component>-name IS INITIAL.

      lv_type = map_internal( <ls_component>-type ).
      rv_type = rv_type && '"' && <ls_component>-name && '":{ ' && lv_type && ' }'.

      IF lv_index <> lines( lt_components ).
        rv_type = rv_type && ','.
      ENDIF.
    ENDLOOP.

    rv_type = rv_type && '}}'.

  ENDMETHOD.                    "map_structure


  METHOD map_table.

    DATA: lv_type  TYPE string,
          lo_table TYPE REF TO cl_abap_tabledescr.


    lo_table ?= io_typedescr.
    lv_type = map_internal( lo_table->get_table_line_type( ) ).
    rv_type = '"schema":{"type":"array", "items":{' && lv_type && '}}'.

  ENDMETHOD.                    "map_table
ENDCLASS.