create or replace PACKAGE BODY             "PCK_CIS_REQUEST" AS

  PROCEDURE PR_CREATE_CIS_REQUEST (
        p_id CIS_REQUEST.ID%TYPE,
        p_cis_no CIS_REQUEST.CIS_NO%TYPE,
        p_channel CIS_REQUEST.CHANNEL%TYPE,
        p_customer_type CIS_REQUEST.CUSTOMER_TYPE%TYPE,
        p_status CIS_REQUEST.STATUS%TYPE,
        p_product_code CIS_REQUEST.PRODUCT_CODE%TYPE,
        p_member_code CIS_REQUEST.MEMBER_CODE%TYPE,
        p_cic_code CIS_REQUEST.CIC_CODE%TYPE,
        p_id_no CIS_REQUEST.ID_NO%TYPE,
        p_tax_code CIS_REQUEST.TAX_CODE%TYPE,
        p_username_request CIS_REQUEST.USERNAME_REQUEST%TYPE,
        p_branch_code CIS_REQUEST.BRANCH_CODE%TYPE,
        p_created_date CIS_REQUEST.CREATED_DATE%TYPE,
        p_requested_date CIS_REQUEST.REQUESTED_DATE%TYPE,
        p_request_data CIS_REQUEST.REQUEST_DATA%TYPE,
        p_err_code CIS_REQUEST.ERR_CODE%TYPE,
        p_err_msg CIS_REQUEST.ERR_MSG%TYPE,
        p_address CIS_REQUEST.ADDRESS%TYPE,
        p_register_no CIS_REQUEST.REGISTER_NO%TYPE,
        p_note CIS_REQUEST.NOTE%TYPE,
        p_customer_name CIS_REQUEST.CUSTOMER_NAME%TYPE,
        p_customer_code CIS_REQUEST.CUSTOMER_CODE%TYPE,
        p_response_date CIS_REQUEST.RESPONSE_DATE%TYPE,
        p_email CIS_REQUEST.EMAIL%TYPE,
        p_last_version CIS_REQUEST.LAST_VERSION%TYPE,
        p_flag CIS_REQUEST.FLAG%TYPE,
        p_msg_id CIS_REQUEST.MSG_ID%TYPE,
        p_application_id CIS_REQUEST.APPLICATION_ID%TYPE,
        p_maker CIS_REQUEST.MAKER%TYPE,
        p_task_id CIS_REQUEST.TASK_ID%TYPE,
        p_encode_request cis_request.encode_request%TYPE,
        p_borrower CIS_REQUEST.BORROWER%TYPE,
        p_pcb_code CIS_REQUEST.PCB_CODE%TYPE,
        p_ccy CIS_REQUEST.CCY%TYPE,
        p_amount_fin_capital CIS_REQUEST.AMOUNT_FIN_CAPITAL%TYPE,
        p_total_instalment CIS_REQUEST.TOTAL_INSTALMENT%TYPE,
        p_credit_limit CIS_REQUEST.CREDIT_LIMIT%TYPE,
        p_gender CIS_REQUEST.GENDER%TYPE,
        p_dob CIS_REQUEST.DOB%TYPE,
        p_doc_type CIS_REQUEST.DOC_TYPE%TYPE,
        p_pay_periodicity CIS_REQUEST.PAY_PERIODICITY%TYPE,
        p_operation_type CIS_REQUEST.OPERATION_TYPE%TYPE,
        p_country_of_birth CIS_REQUEST.COUNTRY_OF_BIRTH%TYPE,
        p_request_id CIS_REQUEST.REQUEST_ID%TYPE,
        p_frequent_contacts CIS_REQUEST.FREQUENT_CONTACTS%TYPE,
        p_phone_number CIS_REQUEST.PHONE_NUMBER%TYPE,
        p_user varchar2,
        p_client_ip varchar2,
        p_user_agent varchar2,
        p_nam_tai_chinh varchar2,
        p_out    OUT SYS_REFCURSOR) 
    AS
        V_ID_CIS_REQUEST VARCHAR2 (2000);
        V_STATUS VARCHAR2(100);
        V_REQUEST_STATUS VARCHAR2(100);
        V_CIS_NO VARCHAR2(15);
        V_PARAMETER VARCHAR2(1000);
        V_COUNT NUMBER;
        V_WARNING_RECORDS NUMBER;
        V_MAX_WARNING_RECORDS NUMBER;
        V_BRANCH VARCHAR2(50);
        V_DEPARTMENT VARCHAR2(50);
        V_ERR_MSG  VARCHAR2(500);
        V_MSG_ID  VARCHAR2(500);
        V_STATUS_BY_CHANEL VARCHAR2(1000);
    BEGIN
        V_ID_CIS_REQUEST:= SEQ_CIS_REQUEST.NEXTVAL;
        V_MSG_ID:=case when p_msg_id in ('null','undefined') then '' else p_msg_id end;

        DBMS_OUTPUT.PUT_LINE ('PR_CREATE_CIS_REQUEST:' || V_ID_CIS_REQUEST);

        SELECT COUNT(9) INTO V_WARNING_RECORDS
        FROM CIS_REQUEST A
        WHERE A.MAKER=nvl(p_maker,p_user) AND TRUNC(A.CREATED_DATE)=TRUNC(SYSDATE) AND A.MSG_ID IS NOT NULL;

        SELECT
	MAX(PKG_UTILITY.IS_NUMBER(A.PAR1)),
	MAX(CIC_DEPARTMENT)
INTO
	V_MAX_WARNING_RECORDS,
	V_DEPARTMENT
FROM
	SYS_GROUPS A
LEFT JOIN SYS_USER B ON
	',' || B.GROUP_NAME || ',' LIKE '%,' || A.GROUP_NAME || ',%'
WHERE
	B.USER_NAME = nvl(p_maker, p_user);

        V_REQUEST_STATUS := P_STATUS;

        IF P_CHANNEL='CIC' THEN--Check dieu kien CIC
           V_STATUS := PCK_CIS_REQUEST.PR_STATUS_MATRIX_CIC(p_id_no, p_register_no, p_tax_code, p_customer_type, p_product_code, p_cic_code);
           IF V_STATUS LIKE 'WAITING:%' THEN
                V_REQUEST_STATUS:='REJECTED_M'; 
                V_ERR_MSG:='Đang đợi bản tin phản hồi';
           END IF;
           IF V_STATUS='WARNING1' OR V_STATUS='WARNING2' OR V_STATUS='WARNING3' OR V_STATUS='WARNING1WARNING3' OR V_STATUS='WARNING2WARNING3' THEN
              IF V_WARNING_RECORDS>=V_MAX_WARNING_RECORDS THEN
                V_REQUEST_STATUS:='REJECTED_M';   
                V_ERR_MSG:='Hỏi tin vượt số lượng cảnh báo';           
              END IF;

              V_PARAMETER := 'channel:CIC,product_code:'|| p_product_code ||',id_no:'||p_id_no ||',tax_code:'||p_tax_code ||',register_no:'||P_register_no ||',customer_type:'||p_customer_type ||',V_WARNING_RECORDS:'||V_WARNING_RECORDS||',V_MAX_WARNING_RECORDS:'||V_MAX_WARNING_RECORDS;
              --pkg_system_log.PR_LOG_EXCEPTION('PR_CREATE_CIS_REQUEST','DEBUG WARNING',V_STATUS,V_PARAMETER);

              SELECT COUNT(9) INTO V_COUNT FROM CIS_MSGID A WHERE A.MSGID=V_MSG_ID;
              IF V_COUNT=-1 THEN--Tam thoi bo dieu kien check MSGID
                V_STATUS:=DBMS_RANDOM.STRING('A', 5);
                pkg_system_log.PR_LOG_EXCEPTION('PR_CREATE_CIS_REQUEST','CHECK PR_STATUS_MATRIX_CIC',V_STATUS,'WRONG MSGID: '||V_MSG_ID ||'|'||V_PARAMETER);
                COMMIT;
                V_REQUEST_STATUS:='REJECTED_M';
                V_ERR_MSG:='Không có thông tin MSGID';    
              END IF;
           END IF;
        END IF;

        IF P_CHANNEL='PCB' THEN
           V_STATUS := PCK_CIS_REQUEST.PR_STATUS_MATRIX_PCB(p_product_code,p_id_no, p_doc_type, P_register_no);
           IF V_STATUS='WARNING1' OR V_STATUS='WARNING2' OR V_STATUS='WARNING3' OR V_STATUS='WARNING1WARNING3' OR V_STATUS='WARNING2WARNING3' THEN
              IF V_WARNING_RECORDS>=V_MAX_WARNING_RECORDS THEN
                raise_application_error( -20000, 'Không thể hỏi tin được, đã hỏi vượt số bản tin cảnh báo! ['||V_WARNING_RECORDS||'] ' );
                RETURN;              
              END IF;
              V_PARAMETER := 'channel:PCB,product_code:'|| p_product_code ||',id_no:'||p_id_no ||',doc_type:'||p_doc_type ||',register_no:'||P_register_no ;
              SELECT COUNT(9) INTO V_COUNT FROM CIS_MSGID A WHERE A.MSGID=P_MSG_ID;
              IF V_COUNT=0 THEN
                V_STATUS:=DBMS_RANDOM.STRING('A', 5);
                pkg_system_log.PR_LOG_EXCEPTION('PR_CREATE_CIS_REQUEST','CHECK PR_STATUS_MATRIX_PCB',V_STATUS,'WRONG MSGID: '||P_MSG_ID ||'|'||V_PARAMETER);
                COMMIT;
                raise_application_error( -20000, 'Không thể hỏi tin được, yêu cầu liên hệ quản trị hệ thống dể hỗ trợ! ['||V_STATUS||'] ' );
                RETURN;
              END IF;
           END IF;
        END IF;

        IF P_CHANNEL='TS' THEN
           V_STATUS := PCK_CIS_REQUEST.PR_STATUS_MATRIX_TS(p_phone_number, p_product_code, '');
           IF V_STATUS='WARNING1' OR V_STATUS='WARNING2' OR V_STATUS='WARNING3' OR V_STATUS='WARNING1WARNING3' OR V_STATUS='WARNING2WARNING3' THEN
              IF V_WARNING_RECORDS>=V_MAX_WARNING_RECORDS THEN
                raise_application_error( -20000, 'Không thể hỏi tin được, đã hỏi vượt số bản tin cảnh báo! ['||V_WARNING_RECORDS||'] ' );
                RETURN;              
              END IF;

              V_PARAMETER := 'channel:PCB,product_code:'|| p_product_code ||',p_phone_number:'||p_phone_number ;
              SELECT COUNT(9) INTO V_COUNT FROM CIS_MSGID A WHERE A.MSGID=P_MSG_ID;
              IF V_COUNT=0 THEN
                V_STATUS:=DBMS_RANDOM.STRING('A', 5);
                pkg_system_log.PR_LOG_EXCEPTION('PR_CREATE_CIS_REQUEST','CHECK PR_STATUS_MATRIX_TS',V_STATUS,'WRONG MSGID: '||P_MSG_ID ||'|'||V_PARAMETER);
                COMMIT;
                raise_application_error( -20000, 'Không thể hỏi tin được, yêu cầu liên hệ quản trị hệ thống dể hỗ trợ! ['||V_STATUS||'] ' );
                RETURN;
              END IF;
           END IF;
        END IF;
        SELECT MAX(A.MEMBER_CODE) INTO V_BRANCH
        FROM SYS_USER A
        WHERE A.USER_NAME = nvl(p_maker,p_user);

        INSERT INTO CIS_REQUEST (ID,
                                CIS_NO,
                                CHANNEL,
                                CUSTOMER_TYPE,
                                STATUS,
                                PRODUCT_CODE,
                                MEMBER_CODE,
                                CIC_CODE,
                                ID_NO,
                                TAX_CODE,
                                USERNAME_REQUEST,
                                BRANCH_CODE,
                                CREATED_DATE,
                                REQUESTED_DATE,
                                REQUEST_DATA,
                                ERR_CODE,
                                ERR_MSG,
                                ADDRESS,
                                REGISTER_NO,
                                NOTE,
                                CUSTOMER_NAME,
                                CUSTOMER_CODE,
                                RESPONSE_DATE,
                                EMAIL,
                                LAST_VERSION,
                                FLAG,
                                MSG_ID,
                                APPLICATION_ID,
                                MAKER,
                                TASK_ID,
                                encode_request,
                                BORROWER, 
                                PCB_CODE, 
                                CCY, 
                                AMOUNT_FIN_CAPITAL, 
                                TOTAL_INSTALMENT, 
                                CREDIT_LIMIT, 
                                GENDER, 
                                DOB, 
                                DOC_TYPE, 
                                PAY_PERIODICITY, 
                                OPERATION_TYPE, 
                                COUNTRY_OF_BIRTH,
                                REQUEST_ID,
                                FREQUENT_CONTACTS,
                                PHONE_NUMBER,
                                USER_,
                                CLIENT_IP,
                                USER_AGENT,
                                IS_DATA,--14/4/2021 Thiet lap gia tri mac dinh N
                                KEYWORD, KEYWORD_ID,-- 4/5/2021 Them tinh nang tim kiem ko dau
                                nam_tai_chinh,
                                DEPARTMENT) 
         VALUES (V_ID_CIS_REQUEST , --ID
                p_cis_no , --CIS_NO
                p_channel , --CHANNEL
                p_customer_type , --CUSTOMER_TYPE
                V_REQUEST_STATUS , --STATUS
                p_product_code , --PRODUCT_CODE
                p_member_code , --MEMBER_CODE
                p_cic_code , --CIC_CODE
                p_id_no , --ID_NO
                p_tax_code , --TAX_CODE
                p_username_request , --USERNAME_REQUEST
                V_BRANCH , --BRANCH_CODE
                p_created_date , --CREATED_DATE
                p_requested_date , --REQUESTED_DATE
                p_request_data , --REQUEST_DATA
                p_err_code , --ERR_CODE
                trim(p_err_msg ||' '|| V_ERR_MSG) , --ERR_MSG
                nvl(p_address ,'N/A') , --ADDRESS
                p_register_no , --REGISTER_NO
                p_note , --NOTE
                p_customer_name , --CUSTOMER_NAME
                p_customer_code , --CUSTOMER_CODE
                p_response_date , --RESPONSE_DATE
                p_email , --EMAIL
                p_last_version , --LAST_VERSION
                p_flag , --FLAG
                case when p_msg_id in ('null','undefined') then '' else p_msg_id end , --MSG_ID
                p_application_id,  --APPLICATION_ID
                nvl(p_maker,p_user),
                case when p_task_id is not null then 'LO' else '' end || p_task_id,
                p_encode_request,
                p_borrower , --BORROWER
                p_pcb_code , --PCB_CODE
                p_ccy , --CCY
                p_amount_fin_capital , --AMOUNT_FIN_CAPITAL
                p_total_instalment , --TOTAL_INSTALMENT
                p_credit_limit , --CREDIT_LIMIT
                p_gender , --GENDER
                p_dob , --DOB
                p_doc_type , --DOC_TYPE
                p_pay_periodicity , --PAY_PERIODICITY
                p_operation_type , --OPERATION_TYPE
                p_country_of_birth,  --COUNTRY_OF_BIRTH
                p_request_id ,
                p_frequent_contacts,
                p_phone_number ,
                P_USER,
                P_CLIENT_IP,
                P_USER_AGENT,
                'N',--14/4/2021 Thiet lap gia tri mac dinh N
                pkg_utility.removesignvietnamess(p_CIS_NO||','||p_REGISTER_NO||','||p_TAX_CODE||','||p_CIC_CODE||'.'||p_CUSTOMER_CODE||','||p_CUSTOMER_NAME||','||p_PRODUCT_CODE||','||nvl(p_maker,p_user)||','|| case when p_task_id is not null then 'LO' else '' end ||p_TASK_ID||','||p_Phone_Number||','||p_Id_No),  -- 4/5/2021 Them tinh nang tim kiem ko dau
                pkg_utility.removesignvietnamess(p_CIS_NO||','||p_REGISTER_NO||','||p_TAX_CODE||','||p_CIC_CODE||','||p_Id_No||','),  -- 4/5/2021 Them tinh nang tim kiem ko dau
                case when p_nam_tai_chinh in ('null','undefined') then '' else p_nam_tai_chinh end ,
                V_DEPARTMENT
                );

    --IF p_flag='1' THEN
      --??ng ký nh?n th𮧠bᯠemail
      SELECT NVL(MAX(CIS_NO),V_ID_CIS_REQUEST) INTO V_CIS_NO
      FROM CIS_REQUEST WHERE ID = V_ID_CIS_REQUEST;

      INSERT INTO CIS_REQUEST_EMAIL (ID, CIS_NO,CREATED_DATE,CREATED_USER,CLIENT_IP,USER_AGENT)
      VALUES (SEQ_CIS_REQUEST_EMAIL.NEXTVAL ,V_CIS_NO, SYSDATE, P_MAKER, P_CLIENT_IP, P_USER_AGENT);
    --END IF;    

    IF p_channel = 'PCB'
        THEN V_STATUS_BY_CHANEL := 'STATUS_REQUEST_PCB';
    ELSE V_STATUS_BY_CHANEL := 'STATUS_REQUEST';
    END IF;

    OPEN p_out FOR
        SELECT CIS_REQUEST.CUSTOMER_NAME, CIS_REQUEST.MSG_ID, CIS_REQUEST.APPLICATION_ID, CIS_REQUEST.REGISTER_NO, CIS_REQUEST.OPERATION_TYPE, CIS_REQUEST.PAY_PERIODICITY,
            CIS_REQUEST.DOC_TYPE, CIS_REQUEST.CUSTOMER_CODE, CIS_REQUEST.CCY, CIS_REQUEST.BORROWER, CIS_REQUEST.ERR_MSG, CIS_REQUEST.NOTE, CIS_REQUEST.ADDRESS,
            CIS_REQUEST.ID, CIS_REQUEST.MAKER, CIS_REQUEST.TASK_ID, CIS_REQUEST.EMAIL, CIS_REQUEST.PCB_CODE, CIS_REQUEST.COUNTRY_OF_BIRTH,
            CIS_REQUEST.GENDER, CIS_REQUEST.FLAG, CIS_REQUEST.LAST_VERSION, CIS_REQUEST.USERNAME_REQUEST, CIS_REQUEST.CIC_CODE, CIS_REQUEST.STATUS,
            CIS_REQUEST.TAX_CODE, CIS_REQUEST.ID_NO, CIS_REQUEST.PRODUCT_CODE, CIS_REQUEST.MEMBER_CODE, CIS_REQUEST.CIS_NO, CIS_REQUEST.CHANNEL,
            CIS_REQUEST.ERR_CODE, CIS_REQUEST.BRANCH_CODE, CIS_REQUEST.CUSTOMER_TYPE, CIS_REQUEST.REQUESTED_DATE, CIS_REQUEST.RESPONSE_DATE, 
            CIS_REQUEST.CREATED_DATE, CIS_REQUEST.AMOUNT_FIN_CAPITAL, CIS_REQUEST.TOTAL_INSTALMENT, CIS_REQUEST.CREDIT_LIMIT, CIS_REQUEST.DOB,CIS_REQUEST.FREQUENT_CONTACTS,CIS_REQUEST.PHONE_NUMBER,
            refStatus.REF_NAME_VN STATUS_STR, refDocType.REF_NAME_VN DOC_TYPE_STR, refCustomerType.REF_NAME_VN CUSTOMER_TYPE_STR,to_char(dob,'DD/MM/YYYY') dob_str,to_char(dob,'DD/MM/YYYY') dobstr
            ,refProduct.REF_NAME_VN PRODUCT_NAME, nam_tai_chinh
            ,DEPARTMENT
        FROM   CIS_REQUEST 
        left JOIN SYS_REFCODE refStatus ON CIS_REQUEST.STATUS = refStatus.REF_CODE AND refStatus.REF_GROUP = V_STATUS_BY_CHANEL
        left JOIN SYS_REFCODE refCustomerType ON CIS_REQUEST.CUSTOMER_TYPE = refCustomerType.REF_CODE AND refCustomerType.REF_GROUP = 'LOAI_KH'
        LEFT JOIN SYS_REFCODE refDocType ON CIS_REQUEST.DOC_TYPE = refDocType.REF_CODE AND refDocType.REF_GROUP = 'DOC_TYPE'
        LEFT JOIN SYS_REFCODE refProduct ON CIS_REQUEST.PRODUCT_CODE = refProduct.REF_CODE AND refProduct.REF_GROUP = 'LS_PRODUCT'
        WHERE  ID = V_ID_CIS_REQUEST;                             

    EXCEPTION
        WHEN ZERO_DIVIDE
        THEN
            DBMS_OUTPUT.PUT_LINE ('Attempt to divide by 0');
  END PR_CREATE_CIS_REQUEST;


    PROCEDURE PR_UPDATE_STATUS_CIS_REQUEST (
        p_cis_no CIS_REQUEST.CIS_NO%TYPE,
        p_status CIS_REQUEST.STATUS%TYPE,
        p_request_data CIS_REQUEST.REQUEST_DATA%TYPE,
        p_msg_id CIS_REQUEST.MSG_ID%TYPE,
        p_err_code CIS_REQUEST.ERR_CODE%TYPE,
        p_err_msg CIS_REQUEST.ERR_MSG%TYPE,
        p_out    OUT SYS_REFCURSOR) 
    AS
        V_STATUS CIS_REQUEST.STATUS%TYPE;
        V_PRODUCT_CODE CIS_REQUEST.PRODUCT_CODE%TYPE;
        V_CUSTOMER_TYPE CIS_REQUEST.CUSTOMER_TYPE%TYPE;
        V_ID_NO CIS_REQUEST.ID_NO%TYPE;
        V_TAX_CODE CIS_REQUEST.TAX_CODE%TYPE;
        V_REGISTER_NO CIS_REQUEST.REGISTER_NO%TYPE;
        V_LAST_VERSION CIS_REQUEST.LAST_VERSION%TYPE;
        V_ERR_MSG varchar2(4000);
        V_FLAG CIS_REQUEST.FLAG%TYPE;
        V_CHANEL CIS_REQUEST.CHANNEL%TYPE;
        V_STATUS_BY_CHANEL VARCHAR2(1000);
    BEGIN

   -- pkg_system_log.PR_LOG_EXCEPTION('PR_UPDATE_STATUS_CIS_REQUEST',p_cis_no||':'||p_status,'',p_request_data);
    V_ERR_MSG:=substr(p_err_msg,1,3900);

    SELECT a.STATUS,a.PRODUCT_CODE, a.CUSTOMER_TYPE, a.ID_NO, a.TAX_CODE, a.REGISTER_NO, a.CHANNEL
    INTO V_STATUS,V_PRODUCT_CODE,V_CUSTOMER_TYPE,V_ID_NO,V_TAX_CODE,V_REGISTER_NO, V_CHANEL
    FROM CIS_REQUEST a 
    WHERE a.CIS_NO=p_cis_no;
    if(V_STATUS = 'TEMP' and p_status = 'NEW') then
        V_LAST_VERSION := '1';

        UPDATE CIS_REQUEST
        SET LAST_VERSION='0'
        where PRODUCT_CODE=V_PRODUCT_CODE
        and case when V_CUSTOMER_TYPE = '0' and V_ID_NO=ID_NO then 1
             when V_CUSTOMER_TYPE = '1' and (V_TAX_CODE=TAX_CODE or V_REGISTER_NO=REGISTER_NO) then 0
             else 0 end = 1;
    end if;

        UPDATE CIS_REQUEST 
            SET STATUS = case when p_err_msg like '%QNA_104%' then 'SENT' else p_status end, 
            REQUEST_DATA = nvl(p_request_data, REQUEST_DATA), 
            MSG_ID = nvl(p_msg_id, MSG_ID) ,          
            err_code = nvl(p_err_code, err_code) ,
            err_msg = nvl(p_err_msg, err_msg),
            LAST_VERSION = nvl(V_LAST_VERSION, LAST_VERSION),
            RESPONSE_DATE = CASE WHEN (p_status IN ('RECEIVED_ERROR', 'RECEIVED','ERROR_DATA')) THEN sysdate ELSE null END,
            REQUESTED_DATE = case when p_status='SENT' then SYSDATE else REQUESTED_DATE end
        --WHERE ','||p_cis_no||',' like '%,'||cis_no||',%';
        WHERE CIS_NO = p_cis_no;
        select flag into V_FLAG from CIS_REQUEST where CIS_NO = p_cis_no;
        IF p_status IN ('RECEIVED_ERROR', 'RECEIVED','ERROR_DATA') THEN
            if V_FLAG = 1 then
                PKG_SYS_EMAIL.PR_SEND_EMAIL_RESPONSE (P_CIS_NO => P_CIS_NO) ;  
            END IF;    
        END IF;
   IF V_CHANEL = 'PCB'
   THEN V_STATUS_BY_CHANEL := 'STATUS_REQUEST_PCB';
   ELSE V_STATUS_BY_CHANEL := 'STATUS_REQUEST';
   END IF;

    OPEN p_out FOR
        SELECT CIS_REQUEST.CUSTOMER_NAME, CIS_REQUEST.MSG_ID, CIS_REQUEST.APPLICATION_ID, CIS_REQUEST.REGISTER_NO, CIS_REQUEST.OPERATION_TYPE, CIS_REQUEST.PAY_PERIODICITY,
            CIS_REQUEST.DOC_TYPE, CIS_REQUEST.CUSTOMER_CODE, CIS_REQUEST.CCY, CIS_REQUEST.BORROWER, CIS_REQUEST.ERR_MSG, CIS_REQUEST.NOTE, CIS_REQUEST.ADDRESS,
            CIS_REQUEST.ID, CIS_REQUEST.MAKER, CIS_REQUEST.TASK_ID, CIS_REQUEST.EMAIL, CIS_REQUEST.PCB_CODE, CIS_REQUEST.COUNTRY_OF_BIRTH,
            CIS_REQUEST.GENDER, CIS_REQUEST.FLAG, CIS_REQUEST.LAST_VERSION, CIS_REQUEST.USERNAME_REQUEST, CIS_REQUEST.CIC_CODE, CIS_REQUEST.STATUS,
            CIS_REQUEST.TAX_CODE, CIS_REQUEST.ID_NO, CIS_REQUEST.PRODUCT_CODE, CIS_REQUEST.MEMBER_CODE, CIS_REQUEST.CIS_NO, CIS_REQUEST.CHANNEL,
            CIS_REQUEST.ERR_CODE, CIS_REQUEST.BRANCH_CODE, CIS_REQUEST.CUSTOMER_TYPE, CIS_REQUEST.REQUESTED_DATE, CIS_REQUEST.RESPONSE_DATE, 
            CIS_REQUEST.CREATED_DATE, CIS_REQUEST.AMOUNT_FIN_CAPITAL, CIS_REQUEST.TOTAL_INSTALMENT, CIS_REQUEST.CREDIT_LIMIT, CIS_REQUEST.DOB,CIS_REQUEST.FREQUENT_CONTACTS,CIS_REQUEST.PHONE_NUMBER,
            refStatus.REF_NAME_VN STATUS_STR, refDocType.REF_NAME_VN DOC_TYPE_STR, refCustomerType.REF_NAME_VN CUSTOMER_TYPE_STR,to_char(dob,'DD/MM/YYYY') dob_str,to_char(dob,'DD/MM/YYYY') dobstr
            ,refProduct.REF_NAME_VN PRODUCT_NAME, CIS_REQUEST.nam_tai_chinh,
           CIS_RESPONSE.RESPONSE_DATA JSON_DATA
        FROM   CIS_REQUEST 
        left join CIS_RESPONSE ON CIS_REQUEST.CIS_NO = CIS_RESPONSE.CIS_NO
        left JOIN SYS_REFCODE refStatus ON CIS_REQUEST.STATUS = refStatus.REF_CODE AND refStatus.REF_GROUP = V_STATUS_BY_CHANEL
        left JOIN SYS_REFCODE refCustomerType ON CIS_REQUEST.CUSTOMER_TYPE = refCustomerType.REF_CODE AND refCustomerType.REF_GROUP = 'LOAI_KH'
        LEFT JOIN SYS_REFCODE refDocType ON CIS_REQUEST.DOC_TYPE = refDocType.REF_CODE AND refDocType.REF_GROUP = 'DOC_TYPE'
        LEFT JOIN SYS_REFCODE refProduct ON CIS_REQUEST.PRODUCT_CODE = refProduct.REF_CODE AND refProduct.REF_GROUP = 'LS_PRODUCT'
        WHERE  CIS_NO = p_cis_no;                             

    EXCEPTION
        WHEN ZERO_DIVIDE
        THEN
            DBMS_OUTPUT.PUT_LINE ('Attempt to divide by 0');
  END PR_UPDATE_STATUS_CIS_REQUEST;

  PROCEDURE PR_GET_LIST_CIS_REQUEST (
        p_id_no CIS_REQUEST.ID_NO%TYPE,
        p_member_code CIS_REQUEST.MEMBER_CODE%TYPE,
        p_register_no CIS_REQUEST.REGISTER_NO%TYPE,
        p_customer_name CIS_REQUEST.CUSTOMER_NAME%TYPE,--Dùng cho KEYWORD
        p_tax_code CIS_REQUEST.TAX_CODE%TYPE,
        p_address CIS_REQUEST.ADDRESS%TYPE,
        p_customer_type CIS_REQUEST.CUSTOMER_TYPE%TYPE,
        p_cic_code CIS_REQUEST.CIC_CODE%TYPE,
        p_customer_code CIS_REQUEST.CUSTOMER_CODE%TYPE,
        p_product_code CIS_REQUEST.PRODUCT_CODE%TYPE,
        p_cis_no CIS_REQUEST.CIS_NO%TYPE,
        p_maker CIS_REQUEST.MAKER%TYPE,
        p_from_date CIS_REQUEST.REQUESTED_DATE%TYPE, -- FROM DATE seach  UI
        p_to_date CIS_REQUEST.REQUESTED_DATE%TYPE, -- TO DATE seach UI
        p_task_id CIS_REQUEST.TASK_ID%TYPE,
        p_status CIS_REQUEST.STATUS%TYPE,
        p_channel CIS_REQUEST.CHANNEL%TYPE,
        p_user varchar2,
        p_out    OUT SYS_REFCURSOR) AS
    v_from_date date;
    v_to_date date;
    V_GROUP_NAME VARCHAR2(1000);
    V_PRODUCT_LIST VARCHAR2(1000);
    V_KEYWORD VARCHAR2(1000);
    V_SEARCH_REQUEST_LIMIT INT;
    V_STATUS_BY_CHANEL VARCHAR2(1000);

   	V_DATE_BET_FROM_TO INT;--NCB_CIC_PCB_2023_PM-26
    BEGIN
          SELECT ','|| listagg(','||NVL(GROUP_NAME,'')||',',', ') within group(order by GROUP_NAME) ||','
          INTO V_GROUP_NAME
          FROM SYS_USER A
          WHERE A.USER_NAME = P_USER;

          SELECT ','|| listagg(','||NVL(PAR2,'')||',',', ') within group(order by PAR2) ||',' INTO  V_PRODUCT_LIST
          FROM SYS_GROUPS A
          WHERE V_GROUP_NAME LIKE '%,'|| A.GROUP_NAME ||',%';

          V_KEYWORD:=pkg_utility.removesignvietnamess(p_customer_name);

          SELECT nvl(MAX(PAR1),0) INTO V_SEARCH_REQUEST_LIMIT
          FROM SYS_REFCODE
          WHERE REF_CODE='SEARCH_REQUEST_LIMIT';

    --v_from_date:=trunc(nvl(p_from_date,add_months(sysdate,-10)));
    --v_to_date:=trunc(nvl(p_to_date,sysdate));
    -- SHB Search theo ?i?u ki?n t?ng tham s?
    /*
    OPEN p_out FOR
        SELECT *
        FROM   CIS_REQUEST
        WHERE (p_id_no IS NULL OR ID_NO = p_id_no) 
              AND (p_member_code IS NULL OR MEMBER_CODE = p_member_code)
              AND (p_register_no IS NULL OR REGISTER_NO = p_register_no) 
              AND (p_customer_name IS NULL OR CUSTOMER_NAME = p_customer_name)
              AND (p_tax_code IS NULL OR TAX_CODE = p_tax_code)
              AND (p_address IS NULL OR ADDRESS like '%'||p_address||'%')
              AND (p_customer_type IS NULL OR CUSTOMER_TYPE = p_customer_type)
              AND (p_cic_code IS NULL OR CIC_CODE = p_cic_code)
              AND (p_customer_code IS NULL OR CUSTOMER_CODE = p_customer_code)
              AND (p_product_code IS NULL OR PRODUCT_CODE = p_product_code)
              AND (p_cis_no IS NULL OR CIS_NO = p_cis_no)
              AND (p_maker IS NULL OR MAKER = p_maker)
              AND (p_from_date IS NULL OR REQUESTED_DATE BETWEEN p_from_date AND p_to_date)
              AND (p_task_id IS NULL OR TASK_ID = p_task_id)
              ORDER BY CREATED_DATE DESC,REQUESTED_DATE DESC;
    */
    -- VIB Search theo KEYWORD
    -- FILTER THEO NGÀY
         --datnd15
    IF V_SEARCH_REQUEST_LIMIT is  null 
        THEN
             v_from_date := null;
             v_to_date := null;
    ELSE
        if p_from_date is null or p_from_date < (sysdate-V_SEARCH_REQUEST_LIMIT)
           then
           v_from_date := sysdate-V_SEARCH_REQUEST_LIMIT;
        else 
            v_from_date:= p_from_date;
        end if; 

        if p_to_date is null or p_to_date < (sysdate-V_SEARCH_REQUEST_LIMIT)
         then
           v_to_date := sysdate;
         else 
            v_to_date:= p_to_date;
        end if;   
    end if;
--    ELSIF p_from_date is null and p_to_date is null
--        then v_from_date := sysdate-V_SEARCH_REQUEST_LIMIT;
--             v_to_date := sysdate;
--    ELSIF p_from_date is not null and p_to_date is null and (sysdate-V_SEARCH_REQUEST_LIMIT)>p_from_date
--        then v_from_date := sysdate-V_SEARCH_REQUEST_LIMIT;
--             v_to_date := sysdate;
--    ELSIF p_from_date is not null and p_to_date is null and (sysdate-V_SEARCH_REQUEST_LIMIT)<p_from_date
--        then v_from_date := p_from_date;
--             v_to_date := sysdate;
--    end if;

    IF p_channel = 'PCB'
          THEN V_STATUS_BY_CHANEL := 'STATUS_REQUEST_PCB';
    ELSE V_STATUS_BY_CHANEL := 'STATUS_REQUEST';
    END IF;

    OPEN p_out FOR
        SELECT CIS_REQUEST.CUSTOMER_NAME,
               CASE WHEN CIS_REQUEST.MSG_ID IS NULL THEN 'No' ELSE 'Yes' END MSG_ID,
               CIS_REQUEST.APPLICATION_ID,
               CIS_REQUEST.REGISTER_NO,
               CIS_REQUEST.OPERATION_TYPE,
               CIS_REQUEST.PAY_PERIODICITY,
               CIS_REQUEST.DOC_TYPE,
               nvl(CIS_REQUEST.CUSTOMER_CODE, '') CUSTOMER_CODE,
               CIS_REQUEST.CCY,
               CIS_REQUEST.BORROWER,
               CIS_REQUEST.ERR_MSG,
               CIS_REQUEST.NOTE,
               CIS_REQUEST.ADDRESS,
               CIS_REQUEST.ID,
               CIS_REQUEST.MAKER,
               CIS_REQUEST.TASK_ID,
               CIS_REQUEST.EMAIL,
               case when CIS_REQUEST.CHANNEL = 'PCB' then 
                 case when CIS_REQUEST.STATUS = 'RECEIVED' then 
                 SUBSTR(cis_response.response_data, 
                 INSTR(cis_response.response_data, '"cbSubjectCode":') + LENGTH('"cbSubjectCode":') + 1,
                 INSTR(SUBSTR(cis_response.response_data, INSTR(cis_response.response_data, '"cbSubjectCode":') + LENGTH('"cbSubjectCode":') + 1), '",') - 1)
                 else null end
               else null end as PCB_CODE, 
--               CIS_REQUEST.PCB_CODE,
               CIS_REQUEST.COUNTRY_OF_BIRTH,
               CIS_REQUEST.GENDER,
               case when exists(select * from cis_request_email xx where xx.cis_no=CIS_REQUEST.cis_no and xx.created_user=p_user) then '1' else '0' end FLAG,
               CIS_REQUEST.LAST_VERSION,
               CIS_REQUEST.USERNAME_REQUEST,
               CIS_REQUEST.CIC_CODE,
               CIS_REQUEST.STATUS,
               CIS_REQUEST.TAX_CODE,
               CIS_REQUEST.ID_NO,
               CIS_REQUEST.PRODUCT_CODE,
               CIS_REQUEST.MEMBER_CODE,
               CIS_REQUEST.CIS_NO,
               CIS_REQUEST.CHANNEL,
               CIS_REQUEST.ERR_CODE,
               CIS_REQUEST.BRANCH_CODE,
               CIS_REQUEST.CUSTOMER_TYPE,
               nvl(CIS_REQUEST.REQUESTED_DATE,CIS_REQUEST.CREATED_DATE) REQUESTED_DATE,
               CIS_REQUEST.RESPONSE_DATE,
               CIS_REQUEST.CREATED_DATE,
               CIS_REQUEST.AMOUNT_FIN_CAPITAL,
               CIS_REQUEST.TOTAL_INSTALMENT,
               CIS_REQUEST.CREDIT_LIMIT,
               CIS_REQUEST.DOB,
               CIS_REQUEST.FREQUENT_CONTACTS,
               CIS_REQUEST.PHONE_NUMBER,
               refStatus.REF_NAME_VN          STATUS_STR,
               refDocType.REF_NAME_VN         DOC_TYPE_STR,
               refCustomerType.REF_NAME_VN    CUSTOMER_TYPE_STR,
               NAM_TAI_CHINH,
               cis_response.response_data raw_data
        FROM   CIS_REQUEST  
        left join cis_response cis_response on cis_response.cis_no = CIS_REQUEST.cis_no
        left JOIN SYS_REFCODE refStatus ON CIS_REQUEST.STATUS = refStatus.REF_CODE AND refStatus.REF_GROUP = V_STATUS_BY_CHANEL
        left JOIN SYS_REFCODE refCustomerType ON CIS_REQUEST.CUSTOMER_TYPE = refCustomerType.REF_CODE AND refCustomerType.REF_GROUP = 'LOAI_KH'
        LEFT JOIN SYS_REFCODE refDocType ON CIS_REQUEST.DOC_TYPE = refDocType.REF_CODE AND refDocType.REF_GROUP = 'DOC_TYPE'
        WHERE ((V_KEYWORD is not null and p_id_no IS NULL AND CIS_REQUEST.KEYWORD like '%'||V_KEYWORD||'%')
              OR (V_KEYWORD is not null and p_id_no IS NOT NULL AND CIS_REQUEST.KEYWORD_ID like '%,'||p_customer_name||',%'))
              AND ((v_from_date is not null and v_to_date is not null and trunc(CIS_REQUEST.REQUESTED_DATE) between trunc(v_from_date) and trunc(v_to_date)) or (CIS_REQUEST.REQUESTED_DATE is null and trunc(CIS_REQUEST.CREATED_DATE) between trunc(v_from_date) and trunc(v_to_date)))
              AND (p_status IS NULL OR p_status = '' OR CIS_REQUEST.STATUS = p_status)
              AND (p_channel IS NULL OR CIS_REQUEST.CHANNEL = p_channel)
              AND (p_maker IS NULL OR MAKER = p_maker)
--               AND CREATED_DATE>SYSDATE-V_SEARCH_REQUEST_LIMIT
--              AND V_PRODUCT_LIST like '%,'|| CIS_REQUEST.PRODUCT_CODE ||',%'
        ORDER BY REQUESTED_DATE DESC;

        -- S? CMT/ H? chi?u, MST, S? ?KKD, M㠫hᣨ h஧ , M㠃IC, Tꮠkhᣨ h஧, Lo?i s?n ph?m, M㠬𬠎g??i h?i tin
        /*
              (p_id_no IS NULL OR ID_NO = p_id_no) 
              AND (p_member_code IS NULL OR MEMBER_CODE = p_member_code)
              AND (p_register_no IS NULL OR REGISTER_NO = p_register_no) 
              AND (p_customer_name IS NULL OR CUSTOMER_NAME = p_customer_name)
              AND (p_tax_code IS NULL OR TAX_CODE = p_tax_code)
              AND (p_address IS NULL OR ADDRESS like '%'||p_address||'%')
              AND (p_customer_type IS NULL OR CUSTOMER_TYPE = p_customer_type)
              AND (p_cic_code IS NULL OR CIC_CODE = p_cic_code)
              AND (p_customer_code IS NULL OR CUSTOMER_CODE = p_customer_code)
              AND (p_product_code IS NULL OR PRODUCT_CODE = p_product_code)
              AND (p_cis_no IS NULL OR CIS_NO = p_cis_no)
              AND (p_maker IS NULL OR MAKER = p_maker)
              AND (p_from_date IS NULL OR REQUESTED_DATE BETWEEN p_from_date AND p_to_date)
              AND (p_task_id IS NULL OR TASK_ID = p_task_id)
              ORDER BY CREATED_DATE DESC,REQUESTED_DATE DESC;
          */                         
    EXCEPTION
        WHEN ZERO_DIVIDE
        THEN
            DBMS_OUTPUT.PUT_LINE ('Attempt to divide by 0');
  END PR_GET_LIST_CIS_REQUEST;

  PROCEDURE PR_GET_CIS_REQUEST_INFO (
        p_cis_no CIS_REQUEST.ID_NO%TYPE,
        p_out    OUT SYS_REFCURSOR)
    AS
    BEGIN
    OPEN p_out FOR
        SELECT CIS_REQUEST.CUSTOMER_NAME, CIS_REQUEST.MSG_ID, CIS_REQUEST.APPLICATION_ID, CIS_REQUEST.REGISTER_NO, CIS_REQUEST.OPERATION_TYPE, CIS_REQUEST.PAY_PERIODICITY,
            CIS_REQUEST.DOC_TYPE, CIS_REQUEST.CUSTOMER_CODE, CIS_REQUEST.CCY, CIS_REQUEST.BORROWER, CIS_REQUEST.ERR_MSG, CIS_REQUEST.NOTE, CIS_REQUEST.ADDRESS,
            CIS_REQUEST.ID, CIS_REQUEST.MAKER, CIS_REQUEST.TASK_ID, CIS_REQUEST.EMAIL, CIS_REQUEST.PCB_CODE, CIS_REQUEST.COUNTRY_OF_BIRTH,
            CIS_REQUEST.GENDER, CIS_REQUEST.FLAG, CIS_REQUEST.LAST_VERSION, CIS_REQUEST.USERNAME_REQUEST, CIS_REQUEST.CIC_CODE, CIS_REQUEST.STATUS,
            CIS_REQUEST.TAX_CODE, CIS_REQUEST.ID_NO, CIS_REQUEST.PRODUCT_CODE, CIS_REQUEST.MEMBER_CODE, CIS_REQUEST.CIS_NO, CIS_REQUEST.CHANNEL,
            CIS_REQUEST.ERR_CODE, CIS_REQUEST.BRANCH_CODE, CIS_REQUEST.CUSTOMER_TYPE, CIS_REQUEST.REQUESTED_DATE, CIS_REQUEST.RESPONSE_DATE, 
            CIS_REQUEST.CREATED_DATE, CIS_REQUEST.AMOUNT_FIN_CAPITAL, CIS_REQUEST.TOTAL_INSTALMENT, CIS_REQUEST.CREDIT_LIMIT, CIS_REQUEST.DOB,CIS_REQUEST.FREQUENT_CONTACTS,CIS_REQUEST.PHONE_NUMBER,
            refStatus.REF_NAME_VN STATUS_STR, refDocType.REF_NAME_VN DOC_TYPE_STR, refCustomerType.REF_NAME_VN CUSTOMER_TYPE_STR,to_char(dob,'DD/MM/YYYY') dob_str,to_char(dob,'DD/MM/YYYY') dobstr
        FROM   CIS_REQUEST 
        JOIN SYS_REFCODE refStatus ON CIS_REQUEST.STATUS = refStatus.REF_CODE AND refStatus.REF_GROUP = 'STATUS_REQUEST'
        JOIN SYS_REFCODE refCustomerType ON CIS_REQUEST.CUSTOMER_TYPE = refCustomerType.REF_CODE AND refCustomerType.REF_GROUP = 'LOAI_KH'
        LEFT JOIN SYS_REFCODE refDocType ON CIS_REQUEST.DOC_TYPE = refDocType.REF_CODE AND refDocType.REF_GROUP = 'DOC_TYPE'
        WHERE  CIS_NO = p_cis_no;

    EXCEPTION
        WHEN ZERO_DIVIDE
        THEN
            DBMS_OUTPUT.PUT_LINE ('Attempt to divide by 0');
  END PR_GET_CIS_REQUEST_INFO;

--Ki?m tra t󺀠h?p l? b?n tin c?a kꮨ CIC
/*
PROCEDURE PR_CHECK_REQUEST_INFO_CIC (
      p_id_no CIS_REQUEST.ID_NO%TYPE,
      p_register_no CIS_REQUEST.REGISTER_NO%TYPE,
      p_tax_code CIS_REQUEST.TAX_CODE%TYPE,
      p_customer_type CIS_REQUEST.CUSTOMER_TYPE%TYPE,
      p_product_code CIS_REQUEST.PRODUCT_CODE%TYPE,
      p_out    OUT SYS_REFCURSOR)
IS
    V_TOTAL_WAITING NUMBER;
    V_TOTAL_POSIABLE NUMBER;
    V_TOTAL_ACTIVE NUMBER;
    V_TOTAL_FRAUD NUMBER;
    V_TOTAL_BLACK_LIST NUMBER;
    V_CONFIG_7 NUMBER;
    V_CONFIG_30 NUMBER;
    v_errors NVARCHAR2 (4000);
    v_flag NUMBER;
BEGIN


    select nvl(max(par1),7) into V_CONFIG_7
    from sys_refcode a where a.ref_code='SO_NGAY_HIEU_LUC_L1';
    select nvl(max(par1),30) into V_CONFIG_30
    from sys_refcode a where a.ref_code='SO_NGAY_HIEU_LUC_L2';

    select sum(case when CIS_REQUEST_STATUS='WAITING' then 1 else 0 end ) WAITING_
           ,sum(case when CIS_REQUEST_STATUS='POSIABLE' then 1 else 0 end ) POSIABLE_
           ,sum(case when CIS_REQUEST_STATUS='ACTIVE' then 1 else 0 end ) ACTIVE_
    into V_TOTAL_WAITING, V_TOTAL_POSIABLE, V_TOTAL_ACTIVE
    from (select case when a.status in ('NEW','SENDED','WAITING','SENDING') then 'WAITING'
                      when trunc(nvl(RESPONSE_DATE,sysdate))>=trunc(sysdate)-V_CONFIG_7 then 'ACTIVE' 
                      when trunc(nvl(RESPONSE_DATE,sysdate))>=trunc(sysdate)-V_CONFIG_30 then 'POSIABLE' 
                      else 'INACTIVE' end CIS_REQUEST_STATUS,
                 a."ID",a."CIS_NO",a."CHANNEL",a."CUSTOMER_TYPE",a."STATUS",a."PRODUCT_CODE",a."MEMBER_CODE",
                 a."CIC_CODE",a."ID_NO",a."TAX_CODE",a."USERNAME_REQUEST",a."BRANCH_CODE",a."CREATED_DATE",
                 a."REQUESTED_DATE",a."REQUEST_DATA",a."ERR_CODE",a."ERR_MSG",a."ADDRESS",a."REGISTER_NO",
                 a."NOTE",a."CUSTOMER_NAME",a."CUSTOMER_CODE",a."RESPONSE_DATE",a."EMAIL",a."LAST_VERSION"
          from CIS_REQUEST a
          where last_version='1' and trunc(nvl(RESPONSE_DATE,sysdate)) >= trunc(sysdate)-V_CONFIG_30) A
    where CUSTOMER_TYPE = p_customer_type and PRODUCT_CODE = ''||p_product_code||''
      and case when p_customer_type = '0' and ID_NO = p_id_no then 1 
           when p_customer_type = '1' and (TAX_CODE = p_tax_code or REGISTER_NO = p_register_no) then 1 
           else 0 end = 1;

    select count(*)
    into V_TOTAL_FRAUD
    from CIS_FRAUDULENCE_CUSTOMER
    where FRAUD_TYPE = 'CUS_FRAUD' and STATUS = '1' --Active
      and case when p_customer_type = '0' and ID_LEGAL_PERSONAL = p_id_no then 1
           when p_customer_type = '1' and (TAX_CODE = p_tax_code or REGISTER_CODE = p_register_no) then 1
           else 0 end = 1;

    select count(*)
    into V_TOTAL_BLACK_LIST
    from CIS_FRAUDULENCE_CUSTOMER
    where FRAUD_TYPE = 'CUS_BLACK_LIST' and STATUS = '1' --Active
      and case when p_customer_type = '0' and ID_LEGAL_PERSONAL = p_id_no then 1
           when p_customer_type = '1' and (TAX_CODE = p_tax_code or REGISTER_CODE = p_register_no) then 1
           else 0 end = 1;
    v_flag := 0;
    if(V_TOTAL_WAITING > 0) then
        v_errors := 'CIS001';
        v_flag := 1;
    end if;
    if(V_TOTAL_ACTIVE > 0) then
        v_errors := v_errors || ',CIS002';
        if (v_flag = 0) then
            v_flag := 2;
        end if;
    end if;
    if(V_TOTAL_POSIABLE > 0) then
       v_errors := v_errors || ',CIS003';
    end if;

    if(V_TOTAL_FRAUD > 0) then
       v_errors := v_errors || ',CIS004';
    end if;
    if(V_TOTAL_BLACK_LIST > 0) then
       v_errors := v_errors || ',CIS005';
    end if;

    OPEN p_out FOR
        SELECT err.errors, nvl(sysRef.REF_NAME_VN, errors) as errors_mess, v_flag as FLAG -- '1' kh𮧠???c ph鰠h?i b?n tin, '0' kh𮧠qua b??c duy?t,'2' B?n tin b?t bu?c qua b??c duy?t
        FROM (select regexp_substr(v_errors,'[^,]+', 1, level) errors from dual
                    connect by regexp_substr(v_errors, '[^,]+', 1, level) is not null) err
        LEFT JOIN SYS_REFCODE sysRef on err.errors = sysRef.REF_CODE and sysRef.REF_GROUP = 'CIS_MESSAGE'
        where err.errors is not null;


END;
*/
FUNCTION PR_CHECK_BLACK_LIST ( p_id_no varchar2) RETURN VARCHAR2
IS
    V_RETURN VARCHAR2(200);
BEGIN

  SELECT MAX(CUSTOMER_NAME) INTO V_RETURN
  FROM CIS_FRAUDULENCE_CUSTOMER A 
  WHERE STATUS='1' AND (ID_LEGAL_PERSONAL=P_ID_NO or A.TAX_CODE=P_ID_NO or A.REGISTER_CODE=P_ID_NO );

RETURN CASE WHEN V_RETURN IS NULL THEN NULL ELSE 'WARNING3' END;

END;
/*
Ki?m tra t쮨 tr?ng d? li?u theo matrix c?a kꮨ PCB
*/
FUNCTION PR_STATUS_MATRIX_PCB( p_product_code  varchar2,
                                      p_id_no  varchar2,
                                      p_doc_type  varchar2,
                                      P_register_no varchar2 ) RETURN VARCHAR2
IS
    V_TOTAL_WARNING1 NUMBER;
    V_TOTAL_WARNING2 NUMBER;
    V_TOTAL_WARNING1WARNING3 NUMBER;
    V_TOTAL_WARNING2WARNING3  NUMBER;
    V_TOTAL_ACCEPT NUMBER; 

    V_TOTAL_FRAUD NUMBER;
    V_TOTAL_BLACK_LIST NUMBER;

    V_PCB_NUMBER_OF_DAYS NUMBER;
    V_PCB_DATA_VALIDATION_DAY NUMBER; 
    v_EXISTS_RECORD NUMBER;
    V_STATUS VARCHAR2(100); 
    V_BLACK_LIST VARCHAR2(100);
BEGIN
/**/
V_BLACK_LIST := PCK_CIS_REQUEST.PR_CHECK_BLACK_LIST(p_id_no);
/*IF V_BLACK_LIST IS NOT NULL THEN
  V_BLACK_LIST := V_BLACK_LIST;
END IF;
*/  

select nvl(max(par1),7) into V_PCB_NUMBER_OF_DAYS
from sys_refcode a where a.ref_code='PCB_NUMBER_OF_DAYS';
select nvl(max(par1),15) into V_PCB_DATA_VALIDATION_DAY
from sys_refcode a where a.ref_code='PCB_DATA_VALIDATION_DAY';


SELECT SUM(CASE WHEN RESPONSE_STATUS='ACCEPT' THEN 1 ELSE 0 END) TOTAL_ACCEPT
       ,SUM(CASE WHEN RESPONSE_STATUS='WARNING1' THEN 1 ELSE 0 END) TOTAL_WARNING1
       ,SUM(CASE WHEN RESPONSE_STATUS='WARNING2' THEN 1 ELSE 0 END) TOTAL_WARNING2
       ,SUM(CASE WHEN RESPONSE_STATUS='WARNING1WARNING3' THEN 1 ELSE 0 END) TOTAL_WARNING1WARNING3
       ,SUM(CASE WHEN RESPONSE_STATUS='WARNING2WARNING3' THEN 1 ELSE 0 END) TOTAL_WARNING2WARNING3
       ,COUNT(9) EXISTS_RECORD
INTO V_TOTAL_ACCEPT, V_TOTAL_WARNING1,V_TOTAL_WARNING2,V_TOTAL_WARNING1WARNING3,V_TOTAL_WARNING2WARNING3,V_EXISTS_RECORD
FROM (
      SELECT CASE WHEN CONDITION_3 = '0' THEN 'ACCEPT' ELSE CASE WHEN V_A>0 THEN CASE WHEN CONDITION_2 = '0' THEN 'ACCEPT'
                                       ELSE CASE WHEN V_C <= V_PCB_DATA_VALIDATION_DAY THEN 'ACCEPT'
                                                 ELSE CASE WHEN V_D >= V_PCB_NUMBER_OF_DAYS THEN 'ACCEPT' 
                                                           ELSE CASE WHEN V_BLACK_LIST is null THEN 'WARNING2' ELSE 'WARNING2WARNING3' END
                                                 END 
                                            END
                                   END
                   ELSE CASE WHEN CONDITION_2 = '0' THEN  'ACCEPT'  ELSE CASE WHEN V_B >= V_PCB_NUMBER_OF_DAYS THEN 'ACCEPT' ELSE CASE WHEN V_BLACK_LIST is null THEN 'WARNING1' ELSE 'WARNING1WARNING3' END END END
                END
              END RESPONSE_STATUS 
      FROM (
        SELECT TO_NUMBER(TO_CHAR(SYSDATE,'DD')) HT
               ,TO_NUMBER(TO_CHAR(A.RESPONSE_DATE,'DD')) GN
               ,TO_NUMBER(TO_CHAR(SYSDATE,'DD'))-V_PCB_DATA_VALIDATION_DAY V_A
               ,TO_NUMBER(TO_CHAR(SYSDATE,'DD'))-TO_NUMBER(TO_CHAR(A.RESPONSE_DATE,'DD')) V_B
               ,GREATEST(TO_NUMBER(TO_CHAR(A.RESPONSE_DATE,'DD')),V_PCB_DATA_VALIDATION_DAY) V_C
               ,TO_NUMBER(TO_CHAR(SYSDATE,'DD'))-GREATEST(TO_NUMBER(TO_CHAR(A.RESPONSE_DATE,'DD')),V_PCB_DATA_VALIDATION_DAY) V_D
               ,CASE WHEN TO_NUMBER(TO_CHAR(SYSDATE,'MM'))=TO_NUMBER(TO_CHAR(A.RESPONSE_DATE,'MM')) THEN '1' ELSE '0' END CONDITION_2
                ,CASE WHEN TO_NUMBER(TO_CHAR(SYSDATE,'YYYY'))=TO_NUMBER(TO_CHAR(A.RESPONSE_DATE,'YYYY')) THEN '1' ELSE '0' END CONDITION_3

        FROM CIS_REQUEST A
        WHERE CHANNEL='PCB'  
              AND A.STATUS='RECEIVED' --AND A.LAST_VERSION='1' 
              --AND A.PRODUCT_CODE=P_PRODUCT_CODE
              AND (A.ID_NO=P_ID_NO OR (A.DOC_TYPE=P_DOC_TYPE AND REGISTER_NO=P_REGISTER_NO))
      ) B
); 

SELECT CASE WHEN v_EXISTS_RECORD=0 and V_BLACK_LIST is null THEN 'NEWCUST' ELSE 
            CASE WHEN V_TOTAL_WARNING1>0 THEN 'WARNING1' WHEN V_TOTAL_WARNING2>0 THEN 'WARNING2' WHEN V_TOTAL_WARNING1WARNING3>0 THEN 'WARNING1WARNING3' WHEN V_TOTAL_WARNING2WARNING3>0 THEN 'WARNING2WARNING3' ELSE (CASE WHEN V_BLACK_LIST is null THEN 'ACCEPT' ELSE 'WARNING3' END) END 
       END
INTO V_STATUS FROM DUAL;

RETURN V_STATUS;
END;

/*
Ki?m tra t쮨 tr?ng d? li?u theo matrix c?a kꮨ CIC
*/
FUNCTION PR_STATUS_MATRIX_CIC(p_id_no CIS_REQUEST.ID_NO%TYPE,
                              p_register_no CIS_REQUEST.REGISTER_NO%TYPE,
                              p_tax_code CIS_REQUEST.TAX_CODE%TYPE,
                              p_customer_type CIS_REQUEST.CUSTOMER_TYPE%TYPE,
                              p_product_code CIS_REQUEST.PRODUCT_CODE%TYPE,
                              p_cic_code varchar2) RETURN VARCHAR2
IS
    V_TOTAL_WARNING1 NUMBER;
    V_TOTAL_WARNING2 NUMBER;
    V_TOTAL_ACCEPT NUMBER; 

    V_TOTAL_FRAUD NUMBER;
    V_TOTAL_BLACK_LIST NUMBER;

    V_CIC_NUMBER_OF_DAYS NUMBER;
    V_CIC_DATA_VALIDATION_DAY NUMBER; 
    v_EXISTS_RECORD NUMBER;
    V_STATUS VARCHAR2(100);
    V_BLACK_LIST VARCHAR2(100);
    V_CIS_NO VARCHAR2(50);
BEGIN
/**/
V_BLACK_LIST := PCK_CIS_REQUEST.PR_CHECK_BLACK_LIST(case when p_id_no is null then case when p_tax_code is null then p_register_no else  p_tax_code end  else p_id_no end);
/*IF V_BLACK_LIST IS NOT NULL THEN
  V_BLACK_LIST := V_BLACK_LIST;
END IF;
*/  
-- Khi s?a PACK n๠c?n update thꭠ? PCK_CIS_OTHER_REQUEST.PR_STATUS_MATRIX_CIC
select nvl(max(par1),7) into V_CIC_NUMBER_OF_DAYS
from sys_refcode a where a.ref_code='CIC_NUMBER_OF_DAYS';
select nvl(max(par1),15) into V_CIC_DATA_VALIDATION_DAY
from sys_refcode a where a.ref_code='CIC_DATA_VALIDATION_DAY';

commit;
IF p_cic_code IS NOT NULL THEN
    SELECT MAX(CIS_NO) INTO V_CIS_NO
    FROM CIS_REQUEST A
    WHERE CHANNEL='CIC' and PRODUCT_CODE = p_product_code
          --AND CUSTOMER_TYPE = p_customer_type
          AND p_cic_code=a.cic_code
          AND A.STATUS IN ('SENDED','SENT','WAITING','NEW') ;

--10/5/2021 - CUONGNH2 - Dieu chinh cach thu truy van
INSERT INTO CIS_REQUEST_CHECK_MATRIX_TMP(HT, GN, V_A, V_B, V_C, V_D, CONDITION_2,CONDITION_3)
SELECT * FROM (
SELECT TO_NUMBER(TO_CHAR(SYSDATE,'DD')) HT
               ,TO_NUMBER(TO_CHAR(A.RESPONSE_DATE,'DD')) GN
               ,TO_NUMBER(TO_CHAR(SYSDATE,'DD'))-V_CIC_DATA_VALIDATION_DAY V_A
               ,CAST((SYSDATE - CAST(A.RESPONSE_DATE AS DATE)) AS INT) V_B
               ,GREATEST(TO_NUMBER(TO_CHAR(A.RESPONSE_DATE,'DD')),V_CIC_DATA_VALIDATION_DAY) V_C
               ,TO_NUMBER(TO_CHAR(SYSDATE,'DD'))-GREATEST(TO_NUMBER(TO_CHAR(A.RESPONSE_DATE,'DD')),V_CIC_DATA_VALIDATION_DAY) V_D
               ,CASE WHEN TO_NUMBER(TO_CHAR(SYSDATE,'MM'))=TO_NUMBER(TO_CHAR(A.RESPONSE_DATE,'MM')) THEN '1' ELSE '0' END CONDITION_2
               ,CASE WHEN TO_NUMBER(TO_CHAR(SYSDATE,'YYYY'))=TO_NUMBER(TO_CHAR(A.RESPONSE_DATE,'YYYY')) THEN '1' ELSE '0' END CONDITION_3
        FROM CIS_REQUEST A
        WHERE CHANNEL='CIC' 
              --AND CUSTOMER_TYPE = p_customer_type 
              and PRODUCT_CODE = p_product_code
              AND p_cic_code=a.cic_code
              AND A.STATUS='RECEIVED' AND A.LAST_VERSION='1'
        ORDER BY CREATED_DATE DESC
              )
WHERE ROWNUM=1;

END IF;
IF V_CIS_NO IS NOT NULL THEN
  RETURN 'WAITING:'||V_CIS_NO;
END IF;

IF p_customer_type = '2' THEN
    SELECT MAX(CIS_NO) INTO V_CIS_NO
    FROM CIS_REQUEST A
    WHERE CHANNEL='CIC' and PRODUCT_CODE = p_product_code
          AND CUSTOMER_TYPE = p_customer_type
          AND ID_NO = p_id_no
          AND A.STATUS IN ('SENDED','SENT','WAITING','NEW');

--10/5/2021 - CUONGNH2 - Dieu chinh cach thu truy van
INSERT INTO CIS_REQUEST_CHECK_MATRIX_TMP(HT, GN, V_A, V_B, V_C, V_D, CONDITION_2, CONDITION_3)
SELECT * FROM (
SELECT TO_NUMBER(TO_CHAR(SYSDATE,'DD')) HT
               ,TO_NUMBER(TO_CHAR(A.RESPONSE_DATE,'DD')) GN
               ,TO_NUMBER(TO_CHAR(SYSDATE,'DD'))-V_CIC_DATA_VALIDATION_DAY V_A
               ,CAST((SYSDATE - CAST(A.RESPONSE_DATE AS DATE)) AS INT) V_B
               ,GREATEST(TO_NUMBER(TO_CHAR(A.RESPONSE_DATE,'DD')),V_CIC_DATA_VALIDATION_DAY) V_C
               ,TO_NUMBER(TO_CHAR(SYSDATE,'DD'))-GREATEST(TO_NUMBER(TO_CHAR(A.RESPONSE_DATE,'DD')),V_CIC_DATA_VALIDATION_DAY) V_D
               ,CASE WHEN TO_NUMBER(TO_CHAR(SYSDATE,'MM'))=TO_NUMBER(TO_CHAR(A.RESPONSE_DATE,'MM')) THEN '1' ELSE '0' END CONDITION_2
               ,CASE WHEN TO_NUMBER(TO_CHAR(SYSDATE,'YYYY'))=TO_NUMBER(TO_CHAR(A.RESPONSE_DATE,'YYYY')) THEN '1' ELSE '0' END CONDITION_3
        FROM CIS_REQUEST A
        WHERE CHANNEL='CIC' AND CUSTOMER_TYPE = p_customer_type and PRODUCT_CODE = p_product_code
              AND ID_NO = p_id_no
              AND A.STATUS='RECEIVED' AND A.LAST_VERSION='1'
        ORDER BY CREATED_DATE DESC
              )
WHERE ROWNUM=1;
END IF;

IF V_CIS_NO IS NOT NULL THEN
  RETURN 'WAITING:'||V_CIS_NO;
END IF;

IF p_customer_type = '1' THEN
    SELECT MAX(CIS_NO) INTO V_CIS_NO
    FROM CIS_REQUEST A
    WHERE CHANNEL='CIC' and PRODUCT_CODE = p_product_code
          AND CUSTOMER_TYPE = p_customer_type
          AND (TAX_CODE = p_tax_code or REGISTER_NO = p_register_no)
          AND A.STATUS IN ('SENDED','SENT','WAITING','NEW');

--10/5/2021 - CUONGNH2 - Dieu chinh cach thu truy van
INSERT INTO CIS_REQUEST_CHECK_MATRIX_TMP(HT, GN, V_A, V_B, V_C, V_D, CONDITION_2, CONDITION_3)
SELECT * FROM (
SELECT TO_NUMBER(TO_CHAR(SYSDATE,'DD')) HT
               ,TO_NUMBER(TO_CHAR(A.RESPONSE_DATE,'DD')) GN
               ,TO_NUMBER(TO_CHAR(SYSDATE,'DD'))-V_CIC_DATA_VALIDATION_DAY V_A
               ,CAST((SYSDATE - CAST(A.RESPONSE_DATE AS DATE)) AS INT) V_B
               ,GREATEST(TO_NUMBER(TO_CHAR(A.RESPONSE_DATE,'DD')),V_CIC_DATA_VALIDATION_DAY) V_C
               ,TO_NUMBER(TO_CHAR(SYSDATE,'DD'))-GREATEST(TO_NUMBER(TO_CHAR(A.RESPONSE_DATE,'DD')),V_CIC_DATA_VALIDATION_DAY) V_D
               ,CASE WHEN TO_NUMBER(TO_CHAR(SYSDATE,'MM'))=TO_NUMBER(TO_CHAR(A.RESPONSE_DATE,'MM')) THEN '1' ELSE '0' END CONDITION_2
               ,CASE WHEN TO_NUMBER(TO_CHAR(SYSDATE,'YYYY'))=TO_NUMBER(TO_CHAR(A.RESPONSE_DATE,'YYYY')) THEN '1' ELSE '0' END CONDITION_3
        FROM CIS_REQUEST A
        WHERE CHANNEL='CIC' AND CUSTOMER_TYPE = p_customer_type and PRODUCT_CODE = p_product_code
              AND (TAX_CODE = p_tax_code or REGISTER_NO = p_register_no)
              AND A.STATUS='RECEIVED' AND A.LAST_VERSION='1'
        ORDER BY CREATED_DATE DESC
              )
WHERE ROWNUM=1;
END IF;
--
--SELECT MAX(CIS_NO) INTO V_CIS_NO
--FROM CIS_REQUEST A
--WHERE CHANNEL='CIC' and PRODUCT_CODE = p_product_code
--      AND CUSTOMER_TYPE = p_customer_type
--      AND ((case when p_customer_type = '2' and ID_NO = p_id_no then 1 
--               when p_customer_type = '1' and (TAX_CODE = p_tax_code or REGISTER_NO = p_register_no) then 1 
--               else 0 end = 1) or p_cic_code=a.cic_code)
--      AND A.STATUS IN ('SENDED','SENT','WAITING','NEW')
--      --AND A.LAST_VERSION='1'
--      ;

IF V_CIS_NO IS NOT NULL THEN
  RETURN 'WAITING:'||V_CIS_NO;
END IF;




SELECT SUM(CASE WHEN RESPONSE_STATUS='ACCEPT' THEN 1 ELSE 0 END) TOTAL_ACCEPT
       ,SUM(CASE WHEN RESPONSE_STATUS='WARNING1' THEN 1 ELSE 0 END) TOTAL_WARNING1
       ,SUM(CASE WHEN RESPONSE_STATUS='WARNING2' THEN 1 ELSE 0 END) TOTAL_WARNING2
       ,COUNT(9) EXISTS_RECORD
INTO V_TOTAL_ACCEPT, V_TOTAL_WARNING1,V_TOTAL_WARNING2, V_EXISTS_RECORD
FROM (
	 SELECT CASE WHEN CONDITION_3 = '0' THEN 'ACCEPT' 
     ELSE CASE WHEN V_A>0 THEN CASE WHEN CONDITION_2 = '0' THEN 'ACCEPT'
                                       ELSE CASE WHEN V_C <= V_CIC_DATA_VALIDATION_DAY THEN 'ACCEPT'
                                                 ELSE CASE WHEN V_D >= V_CIC_NUMBER_OF_DAYS THEN 'ACCEPT' 
                                                           ELSE 'WARNING2' 
                                                      END 
                                            END
                                   END
                   ELSE CASE WHEN V_B >= V_CIC_NUMBER_OF_DAYS THEN 'ACCEPT' ELSE 'WARNING1' END
      END
              END RESPONSE_STATUS 
      FROM (
        SELECT HT, GN, V_A, V_B, V_C, V_D, CONDITION_2, CONDITION_3
        FROM CIS_REQUEST_CHECK_MATRIX_TMP A

      ) B
); 

SELECT CASE WHEN v_EXISTS_RECORD=0 and V_BLACK_LIST is null THEN 'ACCEPT' ELSE 
            CASE WHEN V_TOTAL_WARNING1>0 THEN 'WARNING1' WHEN V_TOTAL_WARNING2>0 THEN 'WARNING2' ELSE (CASE WHEN V_BLACK_LIST is null THEN 'ACCEPT' ELSE '' END) END 
       END
INTO V_STATUS FROM DUAL;

RETURN V_STATUS || V_BLACK_LIST;
END;
--Ki?m tra t󺀠h?p l? b?n tin c?a kꮨ TS
FUNCTION PR_STATUS_MATRIX_TS ( p_phone_number varchar2,
                                      p_product_code varchar2,
                                      p_id_no varchar2) RETURN varchar2
IS
    V_TOTAL_WARNING NUMBER;
    V_TOTAL_ACCEPT NUMBER; 
    V_CONFIG_30 NUMBER;
    v_EXISTS_RECORD NUMBER;
    v_errors NVARCHAR2 (4000);
    v_flag NUMBER;
    V_STATUS VARCHAR2 (40);
    V_BLACK_LIST VARCHAR2 (40);
BEGIN
V_BLACK_LIST := PCK_CIS_REQUEST.PR_CHECK_BLACK_LIST(p_id_no);
/*IF V_BLACK_LIST IS NOT NULL THEN
  RETURN V_BLACK_LIST;
END IF;*/

select nvl(max(par1),30) into V_CONFIG_30
from sys_refcode a where a.ref_code='TS_NUMBER_OF_DAYS';

select sum(case when CIS_REQUEST_STATUS='WARNING1' then 1 else 0 end ) WAITING_
       ,sum(case when CIS_REQUEST_STATUS='ACCEPT' then 1 else 0 end ) ACCEPT_ 
       ,COUNT(9)
into V_TOTAL_WARNING, V_TOTAL_ACCEPT , v_EXISTS_RECORD
from (select case when a.status in ('NEW','SENDED','SENT','WAITING','SENDING') then 'WARNING1'  
                  when trunc(nvl(RESPONSE_DATE,sysdate))>=trunc(sysdate)-V_CONFIG_30 then 'WARNING1' 
                  else 'ACCEPT' end CIS_REQUEST_STATUS,
             a."PRODUCT_CODE",  
             a."RESPONSE_DATE",a."LAST_VERSION", A.PHONE_NUMBER, A.CHANNEL
      from CIS_REQUEST A
      where last_version='1' and trunc(nvl(RESPONSE_DATE,sysdate)) >= trunc(sysdate)-V_CONFIG_30) B
where p_product_code LIKE '%'||B.PRODUCT_CODE||'%'
  and B.PHONE_NUMBER=p_phone_number
  and B.CHANNEL='TS';


/*    OPEN p_out FOR
    SELECT CASE WHEN V_TOTAL_WARNING>0 THEN 'WARNING' ELSE 'ACCEPT' END errors
           ,CASE WHEN V_TOTAL_WARNING>0 THEN V_TOTAL_WARNING ||' row(s)' ELSE '' END  errors_mess, '' FLAG
    FROM DUAL;*/

SELECT CASE WHEN v_EXISTS_RECORD=0 and V_BLACK_LIST IS NULL THEN 'ACCEPT' ELSE 
            CASE WHEN V_TOTAL_WARNING>0 THEN 'WARNING1' ELSE (CASE WHEN V_BLACK_LIST is null THEN 'ACCEPT' ELSE '' END) END 
       END
INTO V_STATUS FROM DUAL;

RETURN V_STATUS||V_BLACK_LIST;


END;

--Ki?m tra t󺀠h?p l? b?n tin c?a kꮨ PCB
PROCEDURE PR_CHECK_REQUEST_INFO_PCB ( p_product_code  varchar2,
                                      p_id_no  varchar2,
                                      p_doc_type  varchar2,
                                      P_register_no varchar2,
                                      p_out    OUT SYS_REFCURSOR)
IS

    V_PARAMETER NVARCHAR2 (4000); 
    V_MSGID VARCHAR2(100);
    V_STATUS VARCHAR2(100);

    V_STATUS_REQUEST VARCHAR2(100);
    V_CIS_NO VARCHAR2(100);
    V_MAKER VARCHAR2(100);
    V_W1 VARCHAR2(1000);
    V_W2 VARCHAR2(1000);
    V_W3 VARCHAR2(1000);
    V_W13 VARCHAR2(1000);
    V_W23 VARCHAR2(1000);
    V_NOTE VARCHAR2(1000);
	V_REQUESTED_DATE CIS_REQUEST.REQUESTED_DATE%TYPE;
    V_RESPONSE_DATE CIS_REQUEST.RESPONSE_DATE%TYPE;
    V_CIC_NUMBER_OF_DAYS VARCHAR2(100);
BEGIN
V_PARAMETER := 'channel:PCB,product_code:'|| p_product_code ||',id_no:'||p_id_no ||',doc_type:'||p_doc_type ||',register_no:'||P_register_no ;
V_STATUS := PCK_CIS_REQUEST.PR_STATUS_MATRIX_PCB(p_product_code, p_id_no, p_doc_type, P_register_no);

IF V_STATUS='WARNING1' OR V_STATUS='WARNING2' OR V_STATUS='WARNING3' OR V_STATUS='WARNING1WARNING3' OR V_STATUS='WARNING2WARNING3' THEN
   SELECT DBMS_RANDOM.STRING('A', 69) INTO V_MSGID FROM DUAL  ;

   INSERT INTO CIS_MSGID(ID, MSGID,CREATE_DATE,DESCRIPTION)
   VALUES (SEQ_CIS_MSGID.NEXTVAL,V_MSGID,SYSDATE,V_PARAMETER);
END IF;

SELECT MAX(CIS_NO) INTO V_CIS_NO
FROM CIS_REQUEST A
WHERE CHANNEL='PCB' --and PRODUCT_CODE = p_product_code
      --AND CUSTOMER_TYPE = p_customer_type
      --AND p_cic_code=a.cic_code
      AND (a.id_no=p_id_no OR a.register_no=P_register_no)
      AND A.STATUS IN ('SENDED','SENT','WAITING','NEW','RECEIVED') ;

SELECT MAX(STATUS)
    ,MAX('Ngày hỏi: '||TO_CHAR(NVL(A.REQUESTED_DATE,A.CREATED_DATE),'DD/MM/YY hh24:mi') ||' => Ngày trả lời: '|| TO_CHAR(A.RESPONSE_DATE,'DD/MM/YY hh24:mi') || ' => Mã phiếu ['|| V_CIS_NO ||']')  
INTO V_STATUS_REQUEST, V_NOTE
FROM CIS_REQUEST A 
WHERE CIS_NO=V_CIS_NO ;

IF V_CIS_NO IS NOT NULL THEN
   SELECT REQUESTED_DATE, RESPONSE_DATE into V_REQUESTED_DATE, V_RESPONSE_DATE from CIS_REQUEST where CIS_NO = V_CIS_NO;
END IF;
    OPEN p_out FOR
    SELECT V_STATUS errors
           ,CASE WHEN V_STATUS='WARNING1' THEN 'Kết quả tra cứu gần đây của Khách hàng đang còn hiệu lực, anh/chị có chắc chắn muốn tra cứu lại không?' 
                 WHEN V_STATUS='WARNING2' THEN 'Kết quả tra cứu gần đây của Khách hàng đang còn hiệu lực, anh/chị có chắc chắn muốn tra cứu lại không?'  
                 /*Start  datnd15 NCB_CIC_PCB_2023_PM-130 27/02/2024*/
                 --WHEN V_STATUS='WARNING3' THEN 'khách hàng thuộc danh sách hạn chế, anh/chị có chắc chắn tiếp tục hỏi tin không?'
                 WHEN V_STATUS='WARNING3' THEN 'Khách hàng thuộc danh sách hạn chế, anh/chị có chắc chắn tiếp tục hỏi tin không?'
                 /*END datnd15 NCB_CIC_PCB_2023_PM-130 27/02/2024*/
                 WHEN V_STATUS='WARNING1WARNING3' THEN 'Khách hàng đang thuộc danh sách hạn chế đồng thời kết quả tra cứu gần đây đang còn hiệu lực, anh/chị có chắc chắn muốn tra cứu lại không ?'
                 WHEN V_STATUS='WARNING2WARNING3' THEN 'Khách hàng đang thuộc danh sách hạn chế đồng thời kết quả tra cứu gần đây đang còn hiệu lực, anh/chị có chắc chắn muốn tra cứu lại không ?'
                 WHEN V_STATUS='ACCEPT' THEN 'Kết quả tra cứu gần đây của Khách hàng đang hết hiệu lực, anh/chị có chắc chắn muốn tra cứu lại không ?'
                 WHEN V_STATUS='NEWCUST' THEN 'Khách hàng chưa có thông tin tại ngân hàng.' 
                 ELSE 'Khách hàng thuộc danh sách gian lận!' END errors_mess
           ,CASE WHEN V_STATUS='WARNING1' OR V_STATUS='WARNING2'  OR V_STATUS='WARNING3' OR V_STATUS='WARNING1WARNING3' OR V_STATUS='WARNING2WARNING3'  THEN V_MSGID ELSE '' END FLAG
           ,V_CIS_NO CIS_NO
           ,V_NOTE NOTE
		   ,V_REQUESTED_DATE REQUESTED_DATE
           ,V_RESPONSE_DATE RESPONSE_DATE
    FROM DUAL;

END;

PROCEDURE PR_CHECK_REQUEST_INFO_CIC ( p_id_no CIS_REQUEST.ID_NO%TYPE,
                                      p_register_no CIS_REQUEST.REGISTER_NO%TYPE,
                                      p_tax_code CIS_REQUEST.TAX_CODE%TYPE,
                                      p_customer_type CIS_REQUEST.CUSTOMER_TYPE%TYPE,
                                      p_product_code CIS_REQUEST.PRODUCT_CODE%TYPE,
                                      p_cic_code varchar2,
                                      p_out    OUT SYS_REFCURSOR)

IS

    V_PARAMETER NVARCHAR2 (4000); 
    V_MSGID VARCHAR2(100);
    V_STATUS VARCHAR2(100);
    V_STATUS_REQUEST VARCHAR2(100);
    V_CIS_NO VARCHAR2(100);
    V_MAKER VARCHAR2(100);
    V_W1 VARCHAR2(1000);
    V_W2 VARCHAR2(1000);
    V_W3 VARCHAR2(1000);
    V_W13 VARCHAR2(1000);
    V_W23 VARCHAR2(1000);
    V_NOTE VARCHAR2(1000);
    V_CIC_NUMBER_OF_DAYS VARCHAR2(100);
	V_REQUESTED_DATE CIS_REQUEST.REQUESTED_DATE%TYPE;
    V_RESPONSE_DATE CIS_REQUEST.RESPONSE_DATE%TYPE;
BEGIN

SELECT MAX(PAR1) INTO V_CIC_NUMBER_OF_DAYS
FROM SYS_REFCODE A WHERE A.REF_GROUP='SYSTEM' AND REF_CODE='CIC_NUMBER_OF_DAYS';

SELECT REPLACE(MAX(PAR1),'[CIC_NUMBER_OF_DAYS]',V_CIC_NUMBER_OF_DAYS) INTO V_W1
FROM SYS_REFCODE A WHERE A.REF_GROUP='ERROR_CODE' AND REF_CODE='W1';

SELECT REPLACE(MAX(PAR1),'[CIC_NUMBER_OF_DAYS]',V_CIC_NUMBER_OF_DAYS) INTO V_W2
FROM SYS_REFCODE A WHERE A.REF_GROUP='ERROR_CODE' AND REF_CODE='W2';

SELECT REPLACE(MAX(PAR1),'[CIC_NUMBER_OF_DAYS]',V_CIC_NUMBER_OF_DAYS) INTO V_W3
FROM SYS_REFCODE A WHERE A.REF_GROUP='ERROR_CODE' AND REF_CODE='W3';

SELECT REPLACE(MAX(PAR1),'[CIC_NUMBER_OF_DAYS]',V_CIC_NUMBER_OF_DAYS) INTO V_W13
FROM SYS_REFCODE A WHERE A.REF_GROUP='ERROR_CODE' AND REF_CODE='W13';

SELECT REPLACE(MAX(PAR1),'[CIC_NUMBER_OF_DAYS]',V_CIC_NUMBER_OF_DAYS) INTO V_W23
FROM SYS_REFCODE A WHERE A.REF_GROUP='ERROR_CODE' AND REF_CODE='W23';

V_STATUS := PCK_CIS_REQUEST.PR_STATUS_MATRIX_CIC(p_id_no, p_register_no, p_tax_code, p_customer_type, p_product_code, p_cic_code);
V_PARAMETER := 'channel:CIC,product_code:'|| p_product_code ||',id_no:'||p_id_no ||',tax_code:'||p_tax_code ||',register_no:'||P_register_no ||',customer_type:'||p_customer_type||',V_STATUS:'||V_STATUS||',cic code:'||p_cic_code ;

--V_STATUS := 'WARNING1';
IF V_STATUS LIKE 'WAITING%' THEN
    V_CIS_NO := REPLACE(V_STATUS,'WAITING:','');

    SELECT MAX(A.MAKER) MAKER INTO V_MAKER
    FROM CIS_REQUEST A
    WHERE CIS_NO=V_CIS_NO;

    OPEN p_out FOR
    SELECT V_STATUS errors
           ,'Bản tin đang chờ CIC phản hồi!' errors_mess
           ,'0' FLAG
           ,'WAITING' STATUS
           ,replace(V_STATUS,'WAITING:','')  CIS_NO
           ,(select max(xx.ref_name_vn) x from sys_refcode xx where ref_code=p_product_code and ref_group='LS_PRODUCT' ) product_name
           ,V_MAKER maker
           --,case when exists(select * from cis_request_email xx where xx.cis_no=V_CIS_NO ) then '0' else '0' end FLAG
    FROM DUAL;
    commit;
    RETURN;
END IF;

IF V_STATUS='WARNING1' OR V_STATUS='WARNING2' OR V_STATUS='WARNING3' OR V_STATUS='WARNING1WARNING3' OR V_STATUS='WARNING2WARNING3' THEN
   SELECT DBMS_RANDOM.STRING('A', 69) INTO V_MSGID FROM DUAL  ;

   INSERT INTO CIS_MSGID(ID, MSGID,CREATE_DATE,DESCRIPTION)
   VALUES (SEQ_CIS_MSGID.NEXTVAL,V_MSGID,SYSDATE,V_PARAMETER);
END IF;


IF p_cic_code IS NOT NULL THEN
    SELECT MAX(CIS_NO) INTO V_CIS_NO
    FROM CIS_REQUEST A
    WHERE CHANNEL='CIC' and PRODUCT_CODE = p_product_code
          --AND CUSTOMER_TYPE = p_customer_type
          AND p_cic_code=a.cic_code
          AND A.STATUS IN ('SENDED','SENT','WAITING','NEW','RECEIVED') ;
END IF;

IF p_customer_type = '2' AND V_CIS_NO IS NULL THEN
    SELECT MAX(CIS_NO) INTO V_CIS_NO
    FROM CIS_REQUEST A
    WHERE CHANNEL='CIC' and PRODUCT_CODE = p_product_code
          AND CUSTOMER_TYPE = p_customer_type
          AND ID_NO = p_id_no
          AND A.STATUS IN ('SENDED','SENT','WAITING','NEW','RECEIVED');
END IF;

IF p_customer_type = '1' AND V_CIS_NO IS NULL THEN
    SELECT MAX(CIS_NO) INTO V_CIS_NO
    FROM CIS_REQUEST A
    WHERE CHANNEL='CIC' and PRODUCT_CODE = p_product_code
          AND CUSTOMER_TYPE = p_customer_type
          AND (TAX_CODE = p_tax_code or REGISTER_NO = p_register_no)
          AND A.STATUS IN ('SENDED','SENT','WAITING','NEW','RECEIVED');
END IF;
--
--SELECT MAX(CIS_NO) INTO V_CIS_NO
--FROM CIS_REQUEST A
--WHERE CHANNEL='CIC' AND CUSTOMER_TYPE = p_customer_type and PRODUCT_CODE = ''||p_product_code||''
--      AND ((case when p_customer_type = '2' and ID_NO = p_id_no then 1 
--               when p_customer_type = '1' and (TAX_CODE = p_tax_code or REGISTER_NO = p_register_no) then 1 
--               else 0 end = 1) or p_cic_code=a.cic_code)
--      AND (A.STATUS='RECEIVED' OR A.STATUS='SENT'  OR A.STATUS='WAITING') AND A.LAST_VERSION='1';

--SELECT MAX(STATUS),MAX('Ng๠h?i: '||TO_CHAR(NVL(A.REQUESTED_DATE,A.CREATED_DATE),'DD/MM/YY hh24:mi') ||'<br />Ng๠tr? l?i: '|| TO_CHAR(A.RESPONSE_DATE,'DD/MM/YY hh24:mi'))  INTO V_STATUS_REQUEST, V_NOTE
--FROM CIS_REQUEST A WHERE CIS_NO=V_CIS_NO;
SELECT MAX(STATUS),MAX('Ngày hỏi: '||TO_CHAR(NVL(A.REQUESTED_DATE,A.CREATED_DATE),'DD/MM/YY hh24:mi') ||'<br />Ngày trả lời: '|| TO_CHAR(A.RESPONSE_DATE,'DD/MM/YY hh24:mi'))  INTO V_STATUS_REQUEST, V_NOTE
FROM CIS_REQUEST A WHERE CIS_NO=V_CIS_NO and   (SELECT MAX(NVL(A.REQUESTED_DATE,A.CREATED_DATE)) FROM CIS_REQUEST B WHERE  B.CIS_NO= V_CIS_NO) = NVL(A.REQUESTED_DATE,A.CREATED_DATE);

IF V_CIS_NO IS NOT NULL THEN
   SELECT REQUESTED_DATE, RESPONSE_DATE into V_REQUESTED_DATE, V_RESPONSE_DATE from CIS_REQUEST where CIS_NO = V_CIS_NO;
END IF;
    OPEN p_out FOR
    SELECT V_STATUS errors
           ,CASE WHEN V_STATUS='WARNING1' THEN V_W1
                 WHEN V_STATUS='WARNING2' THEN V_W2  
                 WHEN V_STATUS='WARNING3' THEN V_W3
                 WHEN V_STATUS='WARNING1WARNING3' THEN V_W13
                 WHEN V_STATUS='WARNING2WARNING3' THEN V_W23
                 WHEN V_STATUS='ACCEPT' THEN '' ELSE 'Khách hàng thuộc danh sách gian lận!' END errors_mess
           ,CASE WHEN V_STATUS='WARNING1' OR V_STATUS='WARNING2'  OR V_STATUS='WARNING3' OR V_STATUS='WARNING1WARNING3' OR V_STATUS='WARNING2WARNING3'  THEN V_MSGID ELSE '' END FLAG
           ,V_CIS_NO CIS_NO
           ,V_STATUS_REQUEST STATUS
           ,V_NOTE NOTE
		   ,V_REQUESTED_DATE REQUESTED_DATE
           ,V_RESPONSE_DATE RESPONSE_DATE
           ,(select max(ref_name_vn) from sys_refcode where ref_code=p_product_code and ref_group='LS_PRODUCT') PRODUCT_NAME
    FROM DUAL;

commit;
END;



--Ki?m tra t󺀠h?p l? b?n tin c?a kꮨ TS
PROCEDURE PR_CHECK_REQUEST_INFO_TS ( p_phone_number varchar2,
                                      p_product_code varchar2,
                                      p_id_no varchar2,
                                      p_out    OUT SYS_REFCURSOR)
IS
    V_PARAMETER NVARCHAR2 (4000); 
    V_MSGID VARCHAR2(100);
    V_STATUS VARCHAR2(100);
BEGIN


V_PARAMETER := 'channel:TS,product_code:'|| p_product_code ||',phone_number:'||p_phone_number||',p_id_no:'||p_id_no ;
V_STATUS := PCK_CIS_REQUEST.PR_STATUS_MATRIX_TS(p_phone_number, p_product_code, p_id_no);

IF V_STATUS='WARNING1' OR V_STATUS='WARNING3' OR V_STATUS='WARNING1WARNING3' OR V_STATUS='WARNING2WARNING3' THEN
   SELECT DBMS_RANDOM.STRING('A', 69) INTO V_MSGID FROM DUAL  ;

   INSERT INTO CIS_MSGID(ID, MSGID,CREATE_DATE,DESCRIPTION)
   VALUES (SEQ_CIS_MSGID.NEXTVAL,V_MSGID,SYSDATE,V_PARAMETER);
END IF;

    OPEN p_out FOR/*
    SELECT V_STATUS errors
           ,CASE WHEN V_STATUS='WARNING1' THEN 'C?nh bᯠkhi tra c?u khᣨ h஧! (WARNING 1)' 
                 WHEN V_STATUS='WARNING3' THEN 'Khᣨ h஧ thu?c danh sᣨ gian l?n! (WARNING 3)'
                 WHEN V_STATUS='ACCEPT' THEN '' 
                 ELSE 'Khᣨ h஧ thu?c danh sᣨ gian l?n!' 
            END errors_mess
           --,CASE WHEN V_STATUS='WARNING' THEN 'C?nh bᯠkhi tra c?u khᣨ h஧! (WARNING)' ELSE '' END errors_mess
           ,CASE WHEN V_STATUS='WARNING' THEN V_MSGID ELSE '' END FLAG
    FROM DUAL;*/
    SELECT V_STATUS errors
           ,CASE WHEN V_STATUS='WARNING1' THEN 'Kết quả tra cứu gần đây của Khách hàng đang còn hiệu lực, anh/chị có chắc chắn muốn tra cứu lại không?' 
                 WHEN V_STATUS='WARNING2' THEN 'Kết quả tra cứu gần đây của Khách hàng đang còn hiệu lực, anh/chị có chắc chắn muốn tra cứu lại không?'  
                 WHEN V_STATUS='WARNING3' THEN 'khách hàng thuộc danh sách hạn chế, anh/chị có chắc chắn tiếp tục hỏi tin không?' 
                 WHEN V_STATUS='WARNING1WARNING3' THEN 'Khách hàng đang thuộc danh sách hạn chế đồng thời kết quả tra cứu gần đây đang còn hiệu lực, anh/chị có chắc chắn muốn tra cứu lại không ?'
                 WHEN V_STATUS='WARNING2WARNING3' THEN 'Khách hàng đang thuộc danh sách hạn chế đồng thời kết quả tra cứu gần đây đang còn hiệu lực, anh/chị có chắc chắn muốn tra cứu lại không ?'
                 WHEN V_STATUS='ACCEPT' THEN '' ELSE 'Khách hàng thuộc danh sách gian lận!' END errors_mess
           ,CASE WHEN V_STATUS='WARNING1' OR V_STATUS='WARNING2'  OR V_STATUS='WARNING3' OR V_STATUS='WARNING1WARNING3' OR V_STATUS='WARNING2WARNING3'  THEN V_MSGID ELSE '' END FLAG
    FROM DUAL;

END;


--Ki?m tra t󺀠h?p l? b?n tin
PROCEDURE PR_CHECK_REQUEST_INFO (
      p_param1 varchar2,
      p_param2 varchar2,
      p_param3 varchar2,
      p_param4 varchar2,
      p_param5 varchar2,
      p_param6 varchar2,
      p_param7 varchar2,
      p_param8 varchar2,
      p_channel varchar2,
      p_user varchar2,
      p_client_ip varchar2,
      p_user_agent varchar2,
      p_out    OUT SYS_REFCURSOR)
IS
BEGIN
/*
OUTPUT: 
    - ERROR: 
           + WARNING/ACCEPT: Tr? v? 2 tr?ng thᩊ           + ERROR_CODE: M㠬?i c? th?
    - ERROR_MESS: N?u ERROR l࠭㠬?i NOT IN (WARNING/ACCEPT) th젳? c󠮿i dung l?i
    - FLAG: Chua s? d?ng
*/
IF p_channel='CIC' THEN
   PR_CHECK_REQUEST_INFO_CIC ( p_id_no => p_param1 ,
                              p_register_no => p_param2,
                              p_tax_code => p_param3,
                              p_customer_type => p_param4,
                              p_product_code => p_param5,
                              p_cic_code => p_param6,
                              p_out =>p_out);
END IF; 
IF p_channel='PCB' THEN
   PR_CHECK_REQUEST_INFO_PCB ( p_id_no => p_param1 ,
                              p_product_code => p_param2,
                              p_doc_type => p_param3,
                              P_register_no => p_param4, 
                              p_out =>p_out);
END IF;
IF p_channel='TS' THEN
   PR_CHECK_REQUEST_INFO_TS ( p_phone_number => p_param1 ,
                              p_product_code => p_param2,
                              p_id_no => p_param3,
                              p_out =>p_out);
END IF;      
commit;
END;

PROCEDURE PR_CHECK_BATCH_REQUEST_INFO ( p_param1 varchar2,
                                        p_param2 varchar2,
                                        p_param3 varchar2,
                                        p_param4 varchar2,
                                        p_param5 varchar2,
                                        p_param6 varchar2,
                                        p_param7 varchar2,
                                        p_param8 varchar2,
                                        p_channel varchar2,
                                        p_user varchar2,
                                        p_client_ip varchar2,
                                        p_user_agent varchar2,
                                        p_out    OUT SYS_REFCURSOR)
IS
V_MSGID nvarchar2(500);
V_PARAMETER nvarchar2(500);
V_STATUS_BY_CHANEL VARCHAR2(1000);

V_ERROR VARCHAR2(500);
BEGIN

 IF p_channel='CIC' THEN
   PR_CHECK_REQUEST_INFO_CIC ( p_id_no => p_param1 ,
                              p_register_no => p_param2,
                              p_tax_code => p_param3,
                              p_customer_type => p_param4,
                              p_product_code => p_param5,
                              p_cic_code => p_param6,
                              p_out =>p_out);
   V_STATUS_BY_CHANEL := 'STATUS_REQUEST';
END IF; 
IF p_channel='PCB' THEN
/*PR_CHECK_REQUEST_INFO_PCB ( p_id_no => p_param1 ,
                          p_product_code => p_param2,
                          p_doc_type => p_param3,
                          P_register_no => p_param4, 
                          p_out =>p_out);
*/
V_PARAMETER := 'channel:PCB,product_code:'|| p_param2 ||',id_no:'||p_param1 ||',doc_type:'||p_param3 ||',register_no:'||p_param4 ;
V_ERROR := PCK_CIS_REQUEST.PR_STATUS_MATRIX_PCB( 'PCB_CN', p_param1, p_param3, p_param4);
V_STATUS_BY_CHANEL := 'STATUS_REQUEST_PCB';
--IF V_ERROR='WARNING1' OR V_ERROR='WARNING2' THEN
IF V_ERROR='WARNING1' OR V_ERROR='WARNING2' OR V_ERROR='WARNING3' OR V_ERROR='WARNING1WARNING3' OR V_ERROR='WARNING2WARNING3' THEN
   SELECT DBMS_RANDOM.STRING('A', 69) INTO V_MSGID FROM DUAL  ;

   INSERT INTO CIS_MSGID(ID, MSGID,CREATE_DATE,DESCRIPTION)
   VALUES (SEQ_CIS_MSGID.NEXTVAL,V_MSGID,SYSDATE,V_PARAMETER);
END IF;

OPEN p_out FOR
SELECT a.*, err.errors, nvl(sysRef.REF_NAME_VN, errors) as errors_mess
,CASE WHEN V_ERROR='WARNING1' OR V_ERROR='WARNING2' OR V_ERROR='WARNING3' OR V_ERROR='WARNING1WARNING3' OR V_ERROR='WARNING2WARNING3'  THEN V_MSGID ELSE NULL END FLAG 
,B.REF_NAME_VN STATUS_STR
,C.REF_NAME_VN DOC_TYPE_STR
,D.REF_NAME_VN CUSTOMER_TYPE_STR
FROM (select regexp_substr(V_ERROR,'[^,]+', 1, level) errors from dual
            connect by regexp_substr(V_ERROR, '[^,]+', 1, level) is not null) err 
LEFT JOIN CIS_REQUEST a on 1=1
LEFT JOIN SYS_REFCODE sysRef on err.errors = sysRef.REF_CODE and sysRef.REF_GROUP = 'CIS_MESSAGE'
LEFT JOIN SYS_REFCODE B on A.STATUS = B.REF_CODE and B.REF_GROUP = V_STATUS_BY_CHANEL
LEFT JOIN SYS_REFCODE C on A.DOC_TYPE = C.REF_CODE and C.REF_GROUP = 'DOC_TYPE'
LEFT JOIN SYS_REFCODE D on A.CUSTOMER_TYPE = D.REF_CODE and D.REF_GROUP = 'LOAI_KH'
where CHANNEL='PCB'  
      AND A.STATUS='RECEIVED' AND A.LAST_VERSION='1' 
      AND A.PRODUCT_CODE='PCB_CN'
      AND (A.ID_NO=p_param1 OR (A.DOC_TYPE=p_param3 AND REGISTER_NO=p_param4));

/*    AND a.CUSTOMER_TYPE = p_customer_type 
    and case when p_customer_type = '0' and a.ID_NO = p_id_no then 1 
    when p_customer_type = '1' and (a.TAX_CODE = p_tax_code or a.REGISTER_NO = p_register_no) then 1 
    else 0 end = 1;*/

/*   PR_CHECK_REQUEST_INFO_PCB ( p_id_no => p_param1 ,
                              p_product_code => 'PCB_CN',
                              p_doc_type => p_param3,
                              P_register_no => p_param4, 
                              p_out =>p_out);
*/
END IF;
IF p_channel='TS' THEN
   PR_CHECK_REQUEST_INFO_TS ( p_phone_number => p_param1 ,
                              p_product_code => p_param2,
                              p_id_no => p_param3,
                              p_out =>p_out);
END IF; 

END PR_CHECK_BATCH_REQUEST_INFO;

PROCEDURE PR_GET_LOT_NO (
      p_user                         IN     VARCHAR2,
      p_client_ip                    IN     VARCHAR2,
      p_user_agent                   IN     VARCHAR2,
      p_out    OUT SYS_REFCURSOR)    AS
  BEGIN
  OPEN p_out FOR
      select 'LOT_'||TO_CHAR(SYSDATE,'DDMMYYYYHHMMSS') TASK_ID from Dual;

  EXCEPTION
      WHEN ZERO_DIVIDE
      THEN
          DBMS_OUTPUT.PUT_LINE ('Attempt to divide by 0');
END PR_GET_LOT_NO;

  PROCEDURE PR_CHECK_BATCH_REQUEST_SHB (
      p_id_no CIS_REQUEST.ID_NO%TYPE,
      p_register_no CIS_REQUEST.REGISTER_NO%TYPE,
      p_tax_code CIS_REQUEST.TAX_CODE%TYPE,
      p_customer_type CIS_REQUEST.CUSTOMER_TYPE%TYPE,
      p_product_code CIS_REQUEST.PRODUCT_CODE%TYPE,
      p_channel CIS_REQUEST.CHANNEL%TYPE,
      p_out    OUT SYS_REFCURSOR)
  IS
      V_TOTAL_WAITING NUMBER;
      V_TOTAL_POSIABLE NUMBER;
      V_TOTAL_ACTIVE NUMBER;
      V_TOTAL_FRAUD NUMBER;
      V_TOTAL_BLACK_LIST NUMBER;
      V_CONFIG_20 NUMBER;
      v_errors NVARCHAR2 (4000);
      v_flag NUMBER;
  BEGIN

  select nvl(max(par1),30) into V_CONFIG_20
  from sys_refcode a where a.ref_code='SO_NGAY_HIEU_LUC_LO';

  select sum(case when CIS_REQUEST_STATUS='WAITING' then 1 else 0 end ) WAITING_
         ,sum(case when CIS_REQUEST_STATUS='POSIABLE' then 1 else 0 end ) POSIABLE_
         ,sum(case when CIS_REQUEST_STATUS='ACTIVE' then 1 else 0 end ) ACTIVE_
  into V_TOTAL_WAITING, V_TOTAL_POSIABLE, V_TOTAL_ACTIVE
  from (select case when a.status in ('NEW','SENDED','SENT','WAITING','SENDING') then 'WAITING'
                    when trunc(nvl(RESPONSE_DATE,sysdate))>=trunc(sysdate)-V_CONFIG_20 then 'ACTIVE' 
                    when trunc(nvl(RESPONSE_DATE,sysdate))>=trunc(sysdate)-(V_CONFIG_20+10) then 'POSIABLE' 
                    else 'INACTIVE' end CIS_REQUEST_STATUS,
               a."ID",a."CIS_NO",a."CHANNEL",a."CUSTOMER_TYPE",a."STATUS",a."PRODUCT_CODE",a."MEMBER_CODE",
               a."CIC_CODE",a."ID_NO",a."TAX_CODE",a."USERNAME_REQUEST",a."BRANCH_CODE",a."CREATED_DATE",
               a."REQUESTED_DATE",a."REQUEST_DATA",a."ERR_CODE",a."ERR_MSG",a."ADDRESS",a."REGISTER_NO",
               a."NOTE",a."CUSTOMER_NAME",a."CUSTOMER_CODE",a."RESPONSE_DATE",a."EMAIL",a."LAST_VERSION"
        from CIS_REQUEST a
        where last_version='1' and trunc(nvl(RESPONSE_DATE,sysdate)) >= trunc(sysdate)-(V_CONFIG_20+10)) A
  where CUSTOMER_TYPE = p_customer_type and PRODUCT_CODE = ''||p_product_code||''
    and case when p_customer_type = '2' and ID_NO = p_id_no then 1 
         when p_customer_type = '1' and (TAX_CODE = p_tax_code or REGISTER_NO = p_register_no) then 1 
         else 0 end = 1;

  select count(*)
  into V_TOTAL_FRAUD
  from CIS_FRAUDULENCE_CUSTOMER
  where FRAUD_TYPE = 'CUS_FRAUD' and STATUS = '1' --Active
    and case when p_customer_type = '2' and ID_LEGAL_PERSONAL = p_id_no then 1
         when p_customer_type = '1' and (TAX_CODE = p_tax_code or REGISTER_CODE = p_register_no) then 1
         else 0 end = 1;

  select count(*)
  into V_TOTAL_BLACK_LIST
  from CIS_FRAUDULENCE_CUSTOMER
  where FRAUD_TYPE = 'CUS_BLACK_LIST' and STATUS = '1' --Active
    and case when p_customer_type = '2' and ID_LEGAL_PERSONAL = p_id_no then 1
         when p_customer_type = '1' and (TAX_CODE = p_tax_code or REGISTER_CODE = p_register_no) then 1
         else 0 end = 1;
  v_flag := 0;
  if(V_TOTAL_WAITING > 0) then
      v_errors := 'CIS001';
      v_flag := 1;
  end if;
  if(V_TOTAL_ACTIVE > 0) then
      v_errors := v_errors || ',CIS006';
      if (v_flag = 0) then
          v_flag := 1;
      end if;
  end if;
  if(V_TOTAL_POSIABLE > 0) then
     v_errors := v_errors || ',CIS003';
  end if;

  if(V_TOTAL_FRAUD > 0) then
     v_errors := v_errors || ',CIS004';
     if (v_flag = 0) then
          v_flag := 1;
      end if;
  end if;
  if(V_TOTAL_BLACK_LIST > 0) then
     v_errors := v_errors || ',CIS005';
     if (v_flag = 0) then
          v_flag := 1;
      end if;
  end if;

  OPEN p_out FOR
      SELECT a.*, err.errors, nvl(sysRef.REF_NAME_VN, errors) as errors_mess, v_flag as FLAG -- '1' kh𮧠???c ph鰠h?i b?n tin, '0' kh𮧠qua b??c duy?t,'2' B?n tin b?t bu?c qua b??c duy?t
      FROM (select regexp_substr(v_errors,'[^,]+', 1, level) errors from dual
                  connect by regexp_substr(v_errors, '[^,]+', 1, level) is not null) err 
      LEFT JOIN CIS_REQUEST a on 1=1
      LEFT JOIN SYS_REFCODE sysRef on err.errors = sysRef.REF_CODE and sysRef.REF_GROUP = 'CIS_MESSAGE'
      where err.errors is not null 
          AND a.CUSTOMER_TYPE = p_customer_type 
          and case when p_customer_type = '2' and a.ID_NO = p_id_no then 1 
          when p_customer_type = '1' and (a.TAX_CODE = p_tax_code or a.REGISTER_NO = p_register_no) then 1 
          else 0 end = 1;

END;

PROCEDURE PR_CHECK_REQUEST_INFO_SHB (
      p_id_no CIS_REQUEST.ID_NO%TYPE,
      p_register_no CIS_REQUEST.REGISTER_NO%TYPE,
      p_tax_code CIS_REQUEST.TAX_CODE%TYPE,
      p_customer_type CIS_REQUEST.CUSTOMER_TYPE%TYPE,
      p_product_code CIS_REQUEST.PRODUCT_CODE%TYPE,
      p_channel CIS_REQUEST.CHANNEL%TYPE,
      p_out    OUT SYS_REFCURSOR)
  IS
      V_TOTAL_WAITING NUMBER;
      V_TOTAL_POSIABLE NUMBER;
      V_TOTAL_ACTIVE NUMBER;
      V_TOTAL_FRAUD NUMBER;
      V_TOTAL_BLACK_LIST NUMBER;
      V_CONFIG_7 NUMBER;
      V_CONFIG_30 NUMBER;
      v_errors NVARCHAR2 (4000);
      v_flag NUMBER;
  BEGIN

  select nvl(max(par1),7) into V_CONFIG_7
  from sys_refcode a where a.ref_code='SO_NGAY_HIEU_LUC_L1';
  select nvl(max(par1),30) into V_CONFIG_30
  from sys_refcode a where a.ref_code='SO_NGAY_HIEU_LUC_L2';

  select sum(case when CIS_REQUEST_STATUS='WAITING' then 1 else 0 end ) WAITING_
         ,sum(case when CIS_REQUEST_STATUS='POSIABLE' then 1 else 0 end ) POSIABLE_
         ,sum(case when CIS_REQUEST_STATUS='ACTIVE' then 1 else 0 end ) ACTIVE_
  into V_TOTAL_WAITING, V_TOTAL_POSIABLE, V_TOTAL_ACTIVE
  from (select case when a.status in ('NEW','SENDED','SENT','WAITING','SENDING') then 'WAITING'
                    when trunc(nvl(RESPONSE_DATE,sysdate))>=trunc(sysdate)-V_CONFIG_7 then 'ACTIVE' 
                    when trunc(nvl(RESPONSE_DATE,sysdate))>=trunc(sysdate)-V_CONFIG_30 then 'POSIABLE' 
                    else 'INACTIVE' end CIS_REQUEST_STATUS,
               a."ID",a."CIS_NO",a."CHANNEL",a."CUSTOMER_TYPE",a."STATUS",a."PRODUCT_CODE",a."MEMBER_CODE",
               a."CIC_CODE",a."ID_NO",a."TAX_CODE",a."USERNAME_REQUEST",a."BRANCH_CODE",a."CREATED_DATE",
               a."REQUESTED_DATE",a."REQUEST_DATA",a."ERR_CODE",a."ERR_MSG",a."ADDRESS",a."REGISTER_NO",
               a."NOTE",a."CUSTOMER_NAME",a."CUSTOMER_CODE",a."RESPONSE_DATE",a."EMAIL",a."LAST_VERSION"
        from CIS_REQUEST a
        where last_version='1' and trunc(nvl(RESPONSE_DATE,sysdate)) >= trunc(sysdate)-V_CONFIG_30) A
  where CUSTOMER_TYPE = p_customer_type and PRODUCT_CODE = ''||p_product_code||''
    and case when p_customer_type = '2' and ID_NO = p_id_no then 1 
         when p_customer_type = '1' and (TAX_CODE = p_tax_code or REGISTER_NO = p_register_no) then 1 
         else 0 end = 1;

  select count(*)
  into V_TOTAL_FRAUD
  from CIS_FRAUDULENCE_CUSTOMER
  where FRAUD_TYPE = 'CUS_FRAUD' and STATUS = '1' --Active
    and case when p_customer_type = '2' and ID_LEGAL_PERSONAL = p_id_no then 1
         when p_customer_type = '1' and (TAX_CODE = p_tax_code or REGISTER_CODE = p_register_no) then 1
         else 0 end = 1;

  select count(*)
  into V_TOTAL_BLACK_LIST
  from CIS_FRAUDULENCE_CUSTOMER
  where FRAUD_TYPE = 'CUS_BLACK_LIST' and STATUS = '1' --Active
    and case when p_customer_type = '2' and ID_LEGAL_PERSONAL = p_id_no then 1
         when p_customer_type = '1' and (TAX_CODE = p_tax_code or REGISTER_CODE = p_register_no) then 1
         else 0 end = 1;
  v_flag := 0;
  if(V_TOTAL_WAITING > 0) then
      v_errors := 'CIS001';
      v_flag := 1;
  end if;
  if(V_TOTAL_ACTIVE > 0) then
      v_errors := v_errors || ',CIS002';
      if (v_flag = 0) then
          v_flag := 2;
      end if;
  end if;
  if(V_TOTAL_POSIABLE > 0) then
     v_errors := v_errors || ',CIS003';
  end if;

  if(V_TOTAL_FRAUD > 0) then
     v_errors := v_errors || ',CIS004';
  end if;
  if(V_TOTAL_BLACK_LIST > 0) then
     v_errors := v_errors || ',CIS005';
  end if;

  OPEN p_out FOR
      SELECT err.errors, nvl(sysRef.REF_NAME_VN, errors) as errors_mess, v_flag as FLAG -- '1' kh𮧠???c ph鰠h?i b?n tin, '0' kh𮧠qua b??c duy?t,'2' B?n tin b?t bu?c qua b??c duy?t
      FROM (select regexp_substr(v_errors,'[^,]+', 1, level) errors from dual
                  connect by regexp_substr(v_errors, '[^,]+', 1, level) is not null) err
      LEFT JOIN SYS_REFCODE sysRef on err.errors = sysRef.REF_CODE and sysRef.REF_GROUP = 'CIS_MESSAGE'
      where err.errors is not null;

END;

PROCEDURE PR_ADD_CIS_REQUEST_EMAIL (
    P_CIS_NO CIS_REQUEST.CIS_NO%TYPE,
    P_USER                         IN     VARCHAR2,
    P_CLIENT_IP                    IN     VARCHAR2,
    P_USER_AGENT                   IN     VARCHAR2,
    P_OUT    OUT SYS_REFCURSOR) IS
    V_ID_CIS_REQUEST_EMAIL VARCHAR2 (2000);
BEGIN
    SELECT NVL(MAX(ID),'0') INTO V_ID_CIS_REQUEST_EMAIL
    FROM CIS_REQUEST_EMAIL WHERE CIS_NO=P_CIS_NO AND CREATED_USER=P_USER;

    IF V_ID_CIS_REQUEST_EMAIL='0' THEN
      V_ID_CIS_REQUEST_EMAIL:= SEQ_CIS_REQUEST_EMAIL.NEXTVAL;
      INSERT INTO CIS_REQUEST_EMAIL(ID, CIS_NO, CREATED_USER,CLIENT_IP,USER_AGENT, CREATED_DATE) 
                            VALUES (V_ID_CIS_REQUEST_EMAIL,P_CIS_NO,P_USER,P_CLIENT_IP,P_USER_AGENT, SYSDATE);
    END IF;

 OPEN P_OUT FOR
  SELECT *
  FROM CIS_REQUEST_EMAIL
  WHERE  ID = V_ID_CIS_REQUEST_EMAIL;

END;


PROCEDURE PR_AUTO_REJECT_REQUEST  IS 
BEGIN

UPDATE CIS_REQUEST 
SET STATUS='REJECT'
WHERE STATUS IN ('SENT','SENDED','WAITING','SENT') 
      AND CREATED_DATE < SYSDATE-200;
COMMIT;           
END;

PROCEDURE PR_GET_LIST_CIS_SENT (
      P_STATUS VARCHAR2,
      P_CHANNEL                         IN     VARCHAR2,
      P_USER                    IN     VARCHAR2,
      P_OUT    OUT SYS_REFCURSOR) AS
BEGIN


  OPEN p_out FOR
  SELECT * FROM CIS_REQUEST
  WHERE CHANNEL=P_CHANNEL AND STATUS=P_STATUS;

--FIX Loi SENDDING - 7/4/2021
  --update CIS_REQUEST
  --set STATUS='SENDING'
  --WHERE CHANNEL=P_CHANNEL AND STATUS=P_STATUS;
END;

--FIX Loi SENDDING - 7/4/2021
PROCEDURE PR_GET_LIST_CIS_NEW (
      P_STATUS VARCHAR2,
      P_CHANNEL                         IN     VARCHAR2,
      P_USER                    IN     VARCHAR2,
      P_OUT    OUT SYS_REFCURSOR) AS
BEGIN

  update CIS_REQUEST
  set STATUS='NEW'
  WHERE CHANNEL=P_CHANNEL 
    AND STATUS='SENDING' 
    AND nvl(REQUESTED_DATE,created_date)+10/24/60<SYSDATE
    AND PRODUCT_CODE<>'S37H'
    AND CHANNEL='CIC'
    AND rownum<10;

  INSERT INTO CIS_REQUEST_ID_TEMPORARY (ID)
  SELECT ID FROM CIS_REQUEST
  WHERE CHANNEL=P_CHANNEL AND STATUS='NEW'
    AND PRODUCT_CODE<>'S37H'
    AND CHANNEL='CIC'
	AND rownum<10;

  OPEN p_out FOR SELECT * FROM CIS_REQUEST WHERE ID IN (SELECT ID FROM CIS_REQUEST_ID_TEMPORARY);

  update CIS_REQUEST
  set STATUS='SENDING', REQUESTED_DATE=SYSDATE
  WHERE ID IN (SELECT ID FROM CIS_REQUEST_ID_TEMPORARY);
  DELETE CIS_REQUEST_ID_TEMPORARY WHERE 1=1;
END;
END PCK_CIS_REQUEST;