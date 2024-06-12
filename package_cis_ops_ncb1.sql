--------------------------------------------------------
--  File created - Tuesday-May-21-2024   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package PCK_CIS_DASHBOARD
--------------------------------------------------------
SET DEFINE OFF;
create or replace PACKAGE             PKG_INSERT_PCB_TALBE AS

  	PROCEDURE SP_INSERT_PCB_TALBE ;


    PROCEDURE PR_BCTH (
        p_idcard VARCHAR2,
        p_type VARCHAR2,
        p_out OUT SYS_REFCURSOR
    ) ;
   
   Function GET_DOCUMENT_ELEMENT(p_cis_no varchar2) RETURN  varchar2;
END ;
/
create or replace PACKAGE BODY PKG_INSERT_PCB_TALBE AS

	PROCEDURE SP_INSERT_PCB_TALBE AS
        vCount NUMBER;
        v_profiles NUMBER;
        vBorrower NUMBER;

       	doc_type	varchar2(1000);
      	doc_number	varchar2(1000);
     	v_result_document	varchar2(1000);
    BEGIN
    	SELECT COUNT(*) INTO vCount FROM CIS_RESPONSE
        WHERE cis_no IN (SELECT cis_no FROM cis_request WHERE channel = 'PCB' AND status= 'RECEIVED')
        AND cis_no NOT IN (SELECT cis_no FROM pcb_Credit_History);

        IF vCount > 0 THEN
        	FOR ctr IN (SELECT * FROM CIS_RESPONSE
                            WHERE cis_no IN (SELECT cis_no FROM cis_request WHERE channel = 'PCB' AND status= 'RECEIVED')
                            AND cis_no NOT IN (SELECT cis_no FROM pcb_Credit_History)
            		    )
            LOOP
            	SELECT COUNT(*) INTO vBorrower FROM cis_request a WHERE a.CIS_NO = ctr.CIS_NO AND borrower = '1';

                IF vBorrower > 0 THEN --'rIReqOutput'

                    --inset bang tt chung
                    INSERT INTO PCB_TT_CHUNG (response_id, cis_no, cbsubjectcode, fisubjectcode,
                        name, gender, dateofbirth, countryofbirth,
                        main_address, main_additional, document_type,
                        document_number, document_dateissued, idcard, tin,
                        person_historicaladdress, person_reference)
                    SELECT ctr.id response_id, ctr.cis_no, a.cbsubjectcode, a.fisubjectcode,
                        a.name, a.gender, TO_DATE(a.dateofbirth,'dd/mm/yyyy') dateofbirth, a.countryofbirth,
                        a.main_address, a.main_additional, a.document_type,
                        a.document_number,TO_DATE(a.document_dateissued,'dd/mm/yyyy') document_dateissued, a.idcard, tin,
                        a.idcard person_historicaladdress,a.idcard person_reference
                    FROM
                    (SELECT JS.*
                    FROM JSON_TABLE(ctr.response_data, '$.rIReqOutput.subject.matched'
                        COLUMNS
                            (cbSubjectCode VARCHAR2(20) PATH '$.cbSubjectCode',
                            fiSubjectCode VARCHAR2(20) PATH '$.fiSubjectCode',
                            name VARCHAR2(500) PATH '$.person.name',
                            gender VARCHAR2(500) PATH '$.person.gender',
                            dateOfBirth VARCHAR2(500) PATH '$.person.dateOfBirth',
                            countryOfBirth VARCHAR2(500) PATH '$.person.countryOfBirth',
                            MAIN_ADDRESS  VARCHAR2(500) PATH '$.person.address.main.fullAddress',
                            MAIN_ADDITIONAL  VARCHAR2(500) PATH '$.person.address.additional.fullAddress',
                            DOCUMENT_TYPE  VARCHAR2(500) PATH '$.person.document.type',
                            DOCUMENT_NUMBER  VARCHAR2(500) PATH '$.person.document.number',
                            DOCUMENT_DATEISSUED  VARCHAR2(500) PATH '$.person.document.dateIssued',
                            idCard  VARCHAR2(500) PATH '$.person.idCard',
                            tin  VARCHAR2(500) PATH '$.person.tin'
                            )) AS js
                    ) a ;
                  /*Datnd15 update code start*/
                   v_result_document := CIS_OPS_NCB.PCK_SERVICE_NCB.RUN_TEST(ctr.CIS_NO);
                   IF v_result_document IS NOT NULL THEN
	                   SELECT 	REGEXP_SUBSTR(v_result_document, '[^@]+', 1, 1),
					       		REGEXP_SUBSTR(v_result_document, '[^@]+', 1, 2)
					   INTO doc_type,doc_number
					   FROM dual;
					  UPDATE PCB_TT_CHUNG SET DOCUMENT_TYPE = doc_type , DOCUMENT_NUMBER =doc_number WHERE PCB_TT_CHUNG.CIS_NO = ctr.CIS_NO;
				   END IF;
				  /*Datnd15 update code END*/
                    --insert  bang tt chung reference
                    INSERT INTO pcb_tt_chung_reference (auto_id, cis_no, reference_id, type, ref_number)
                    SELECT seq_pcb_tt_chung_dtl.NEXTVAL, ctr.cis_no, idCard,  TYPE, ref_number
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rIReqOutput.subject.matched.person'
                        COLUMNS
                            (
                            idCard PATH '$.idCard',
                            NESTED PATH '$.reference[*]'
                                COLUMNS (
                                type  PATH '$.type',
                                ref_number PATH '$.number')
                            )) AS js
                    ) a;

                    --insert  bang tt chung historicaladdress_main
                    INSERT INTO pcb_tt_chung_historicaladdress_main (auto_id ,historicaladdress_main_id,cis_no ,fulladdress)
                    SELECT seq_pcb_tt_chung_dtl.NEXTVAL, idCard , ctr.cis_no, fulladdress
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rIReqOutput.subject.matched.person'
                        COLUMNS
                            (
                            idCard PATH '$.idCard',
                            NESTED PATH '$.historicalAddress.main[*]'
                                COLUMNS (
                                fullAddress  PATH '$.fullAddress')
                            )) AS js
                    ) a;

                    --insert lich su the
                    INSERT INTO pcb_Credit_History (response_id, cis_no,
                        cbContractCode, typeOfFinancing, totalNumberOfContract,
                        numberOfReportingInstitution, worstRecentStatus, instalments_id,
                        nonInstalments_id, cards_id, currencyCode, percentage)
                    SELECT ctr.id response_id, ctr.cis_no,
                        cbContractCode, typeOfFinancing, totalNumberOfContract,
                        numberOfReportingInstitution, worstRecentStatus, ctr.cis_no,
                         ctr.cis_no,  ctr.cis_no, currencyCode, percentage
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rIReqOutput.creditHistory'
                        COLUMNS
                            (cbContractCode PATH '$.inquiredOperation.cbContractCode',
                            typeOfFinancing PATH '$.inquiredOperation.typeOfFinancing',
                            totalNumberOfContract PATH '$.generalData.totalNumberOfContract',
                            numberOfReportingInstitution PATH '$.generalData.numberOfReportingInstitution',
                            worstRecentStatus PATH '$.generalData.worstRecentStatus',
                            currencyCode PATH '$.currencySummary.currencyPercentage.currencyCode',
                            percentage PATH '$.currencySummary.currencyPercentage.percentage'
                            )) AS js
                    ) a;

                    --insert hop dong vay tt
                    INSERT INTO pcb_hop_dong_vay_tt (response_id, cis_no, id_tt, numberofliving, numberofrefused,
                       numberofrenounced, numberofterminated,
                       acinstamounts_monthly,
                       acinstamounts_remaining, acinstamounts_unpaiddue,
                       ginstamounts_monthly, ginstamounts_remaining,
                       ginstamounts_unpaiddue)
                    SELECT ctr.id response_id, ctr.cis_no, ctr.cis_no||'-TT', numberofliving, numberofrefused,
                       numberofrenounced, numberofterminated,
                       acinstamounts_monthly,
                       acinstamounts_remaining, acinstamounts_unpaiddue,
                       ginstamounts_monthly, ginstamounts_remaining,
                       ginstamounts_unpaiddue
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rIReqOutput.creditHistory.contract.instalments'
                        COLUMNS
                            (numberOfLiving VARCHAR2(20) PATH '$.summary.numberOfLiving',
                            numberOfRefused VARCHAR2(20) PATH '$.summary.numberOfRefused',
                            numberOfRenounced VARCHAR2(500) PATH '$.summary.numberOfRenounced',
                            numberOfTerminated VARCHAR2(500) PATH '$.summary.numberOfTerminated',
                            --
                            acinstamounts_monthly VARCHAR2(500) PATH '$.aCInstAmounts.monthlyInstalmentsAmount',
                            acinstamounts_remaining VARCHAR2(500) PATH '$.aCInstAmounts.remainingInstalmentsAmount',
                            acinstamounts_unpaiddue  VARCHAR2(500) PATH '$.aCInstAmounts.unpaidDueInstalmentsAmount',
                            ginstamounts_monthly  VARCHAR2(500) PATH '$.gInstAmounts.monthlyInstalmentsAmount',
                            ginstamounts_remaining  VARCHAR2(500) PATH '$.gInstAmounts.remainingInstalmentsAmount',
                            ginstamounts_unpaiddue  VARCHAR2(500) PATH '$.gInstAmounts.unpaidDueInstalmentsAmount'
                            )) AS js
                    ) a;

                    --insert hop dong duoc cap
                    INSERT INTO pcb_hop_dong_duoc_cap (grantedcontract_id, auto_id, currency, referencenumber,
                        role, encryptedficode, typeoffinancing, contractphase,
                        startingdate, dateoflastupdate, cbcontractcode, profiles,
                        endDateOfContract, methodOfPayment,totalNumberOfInstalments ,
                        paymentsPeriodicity,nextDueInstalmentAmount, totalAmount,
                        monthlyInstalmentAmount, remainingInstalmentsNumber,remainingInstalmentsAmount,
                        lastPaymentDate,unpaidDueInstalmentsNumber ,unpaidDueInstalmentsAmount,
                        maximumUnpaidAmount, guarantedAmountFromGuarantor, personalGuaranteeAmount,
                        maximumLevelOfDefault, monthswithmaxlevelofdefault, nrOfDaysOfPaymentDelay,
                        worstStatus,dateWorstStatus,maxNrOfDaysOfPaymentDelay,
                        reorganizedCredit,dateMaxNrOfDaysOfPaymentDelay)
                    SELECT ctr.cis_no||'-TT' grantedcontract_id,
                       SEQ_PCB_HOP_DONG_DUOC_CAP.NEXTVAL auto_id, currency, referencenumber,
                        role, encryptedficode, typeoffinancing, contractphase,
                        TO_DATE(startingdate,'dd/mm/yyyy'), TO_DATE(dateoflastupdate,'dd/mm/yyyy'), cbcontractcode,cbContractCode||'-'||ctr.cis_no profiles,
                        TO_DATE(endDateOfContract,'dd/mm/yyyy'), methodOfPayment,totalNumberOfInstalments ,
                        paymentsPeriodicity,nextDueInstalmentAmount, totalAmount,
                        monthlyInstalmentAmount, remainingInstalmentsNumber,remainingInstalmentsAmount,
                        TO_DATE(lastPaymentDate,'dd/mm/yyyy'),unpaidDueInstalmentsNumber ,unpaidDueInstalmentsAmount,
                        maximumUnpaidAmount, guarantedAmountFromGuarantor, personalGuaranteeAmount,
                        maximumLevelOfDefault, monthswithmaxlevelofdefault, nrOfDaysOfPaymentDelay,
                        worstStatus,TO_DATE(dateWorstStatus,'dd/mm/yyyy'),maxNrOfDaysOfPaymentDelay,
                        reorganizedCredit,TO_DATE(dateMaxNrOfDaysOfPaymentDelay,'dd/mm/yyyy')
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rIReqOutput.creditHistory.contract.instalments.grantedContract[*]'
                        COLUMNS
                            (currency VARCHAR2(20) PATH '$.commonData.currency',
                            referenceNumber VARCHAR2(20) PATH '$.commonData.referenceNumber',
                            role VARCHAR2(20) PATH '$.commonData.role',
                            encryptedFICode VARCHAR2(20) PATH '$.commonData.encryptedFICode',
                            typeOfFinancing VARCHAR2(20) PATH '$.commonData.typeOfFinancing',
                            contractPhase VARCHAR2(20) PATH '$.commonData.contractPhase',
                            startingDate VARCHAR2(20) PATH '$.commonData.startingDate',
                            dateOfLastUpdate VARCHAR2(20) PATH '$.commonData.dateOfLastUpdate',
                            cbContractCode VARCHAR2(20) PATH '$.commonData.cbContractCode',
                            endDateOfContract  VARCHAR2(200) PATH '$.endDateOfContract',
                            methodOfPayment  VARCHAR2(200) PATH '$.methodOfPayment',
                            totalNumberOfInstalments VARCHAR2(200) PATH '$.totalNumberOfInstalments',
                            paymentsPeriodicity VARCHAR2(200) PATH '$.paymentsPeriodicity',
                            nextDueInstalmentAmount VARCHAR2(200) PATH '$.nextDueInstalmentAmount',
                            totalAmount VARCHAR2(200) PATH '$.totalAmount',
                            monthlyInstalmentAmount VARCHAR2(200) PATH '$.monthlyInstalmentAmount',
                            remainingInstalmentsNumber VARCHAR2(200) PATH '$.remainingInstalmentsNumber',
                            remainingInstalmentsAmount VARCHAR2(200) PATH '$.remainingInstalmentsAmount',
                            lastPaymentDate VARCHAR2(200) PATH '$.lastPaymentDate',
                            unpaidDueInstalmentsNumber VARCHAR2(200) PATH '$.unpaidDueInstalmentsNumber',
                            unpaidDueInstalmentsAmount VARCHAR2(200) PATH '$.unpaidDueInstalmentsAmount',
                            maximumUnpaidAmount VARCHAR2(200) PATH '$.maximumUnpaidAmount',
                            guarantedAmountFromGuarantor VARCHAR2(200) PATH '$.guarantedAmountFromGuarantor',
                            personalGuaranteeAmount VARCHAR2(200) PATH '$.personalGuaranteeAmount',
                            maximumLevelOfDefault VARCHAR2(200) PATH '$.maximumLevelOfDefault',
                            monthswithmaxlevelofdefault VARCHAR2(200) PATH '$.numberOfMonthsWithMaximumLevelOfDefault',
                            nrOfDaysOfPaymentDelay VARCHAR2(200) PATH '$.nrOfDaysOfPaymentDelay',
                            worstStatus VARCHAR2(200) PATH '$.worstStatus',
                            dateWorstStatus VARCHAR2(200) PATH '$.dateWorstStatus',
                            maxNrOfDaysOfPaymentDelay VARCHAR2(200) PATH '$.maxNrOfDaysOfPaymentDelay',
                            reorganizedCredit VARCHAR2(200) PATH '$.reorganizedCredit',
                            dateMaxNrOfDaysOfPaymentDelay VARCHAR2(200) PATH '$.dateMaxNrOfDaysOfPaymentDelay'
                                )) AS js
                    ) a;


                    --insert hop dong khong duoc cap
                    INSERT INTO pcb_hop_dong_khong_duoc_cap (notgrantedcontract_id,
                       auto_id, contractphase,
                       typeoffinancing, role, referencenumber, encryptedficode,
                       requestdateofthecontract, totalnumberofinstalments,
                       paymentperiodicity, totalamount, monthlyinstalmentamount,
                       cbcontractcode)
                    SELECT ctr.cis_no||'-TT' notgrantedcontract_id,
                       SEQ_PCB_HOP_DONG_DUOC_CAP.NEXTVAL auto_id,contractphase,
                       typeoffinancing, role, referencenumber, encryptedficode,
                       TO_DATE(requestdateofthecontract,'dd/mm/yyyy'), totalnumberofinstalments,
                       paymentperiodicity, totalamount, monthlyinstalmentamount,
                       cbcontractcode
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rIReqOutput.creditHistory.contract.instalments.notGrantedContract[*]'
                            COLUMNS
                                (contractPhase VARCHAR2(20) PATH '$.contractPhase',
                                typeOfFinancing VARCHAR2(20) PATH '$.typeOfFinancing',
                                role VARCHAR2(500) PATH '$.role',
                                referenceNumber VARCHAR2(500) PATH '$.referenceNumber',
                                encryptedFICode VARCHAR2(500) PATH '$.encryptedFICode',
                                requestDateOfTheContract VARCHAR2(500) PATH '$.amounts.requestDateOfTheContract',
                                totalNumberOfInstalments  VARCHAR2(500) PATH '$.amounts.totalNumberOfInstalments',
                                paymentPeriodicity  VARCHAR2(500) PATH '$.amounts.paymentPeriodicity',
                                totalAmount  VARCHAR2(500) PATH '$.amounts.totalAmount',
                                monthlyInstalmentAmount  VARCHAR2(500) PATH '$.amounts.monthlyInstalmentAmount',
                                cbContractCode VARCHAR2(500) PATH '$.cbContractCode'
                                )) AS js
                    ) a;

                    --insert hop dong duoc cap detail
                    INSERT INTO pcb_hop_dong_duoc_cap_dtl (profiles_id, auto_id,
                        referenceyear, referencemonth, status, default_dtl)
                    SELECT cbContractCode||'-'||ctr.cis_no profiles_id, seq_pcb_hop_dong_duoc_cap_dtl.NEXTVAL auto_id,
                        referenceyear, referencemonth, status, vdefault default_dtl
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rIReqOutput.creditHistory.contract.instalments.grantedContract[*]'
                        COLUMNS
                            (
                            cbContractCode PATH '$.commonData.cbContractCode',
                            NESTED PATH '$.profiles[*]'
                                COLUMNS (
                                referenceYear  PATH '$.referenceYear',
                                referenceMonth PATH '$.referenceMonth',
                                status PATH '$.status',
                                vdefault PATH '$.default')
                            )) AS js
                    ) a;

                    --insert hop dong thau chi
                    INSERT INTO pcb_hop_dong_vay_tc ( response_id, cis_no, id_tc, numberofliving, numberofrefused,
                        numberofrenounced, numberofterminated,
                        acno_creditlimit, acno_utilization, acno_overdraft,
                        gno_creditlimit, gno_utilization, gno_overdraft)
                    SELECT ctr.id, ctr.cis_no, ctr.cis_no||'-TC' id_tc,numberofliving, numberofrefused,
                        numberofrenounced, numberofterminated,
                        acno_creditlimit, acno_utilization, acno_overdraft,
                        gno_creditlimit, gno_utilization, gno_overdraft
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rIReqOutput.creditHistory.contract.nonInstalments[*]'
                        COLUMNS
                            (
                            numberOfLiving VARCHAR2(200) PATH '$.summary.numberOfLiving',
                            numberOfRefused VARCHAR2(200) PATH '$.summary.numberOfRefused',
                            numberOfRenounced VARCHAR2(200) PATH '$.summary.numberOfRenounced',
                            numberOfTerminated VARCHAR2(200) PATH '$.summary.numberOfTerminated',
                            acno_creditlimit VARCHAR2(200) PATH '$.aCNoInstAmounts.creditLimit',
                            acno_utilization VARCHAR2(200) PATH '$.aCNoInstAmounts.utilization',
                            acno_overdraft VARCHAR2(200) PATH '$.aCNoInstAmounts.overdraft',
                            gno_creditlimit VARCHAR2(200) PATH '$.gNoInstAmounts.creditLimit',
                            gno_utilization VARCHAR2(200) PATH '$.gNoInstAmounts.utilization',
                            gno_overdraft VARCHAR2(200) PATH '$.gNoInstAmounts.overdraft'
                            )) AS js
                    ) a;

                    --insert hop dong ko duoc cap thau chi
                    INSERT INTO pcb_hop_dong_khong_duoc_cap (notgrantedcontract_id,
                       auto_id, contractphase,
                       typeoffinancing, role, referencenumber, encryptedficode,
                       requestdateofthecontract, totalAmount, cbcontractcode)
                    SELECT ctr.cis_no||'-TC' notgrantedcontract_id,
                       SEQ_PCB_HOP_DONG_DUOC_CAP.NEXTVAL auto_id,contractphase,
                       typeoffinancing, role, referencenumber, encryptedficode,
                       TO_DATE(requestdateofthecontract,'dd/mm/yyyy'), totalAmount,
                       cbcontractcode
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rIReqOutput.creditHistory.contract.nonInstalments.notGrantedContract[*]'
                            COLUMNS
                                (contractPhase VARCHAR2(20) PATH '$.contractPhase',
                                typeOfFinancing VARCHAR2(20) PATH '$.typeOfFinancing',
                                role VARCHAR2(500) PATH '$.role',
                                referenceNumber VARCHAR2(500) PATH '$.referenceNumber',
                                encryptedFICode VARCHAR2(500) PATH '$.encryptedFICode',
                                requestDateOfTheContract VARCHAR2(500) PATH '$.amounts.requestDateOfTheContract',
                                totalAmount  VARCHAR2(500) PATH '$.amounts.totalAmount',
                                cbContractCode VARCHAR2(500) PATH '$.cbContractCode'
                                )) AS js
                    ) a;

                    --insert hop dong duoc cap thau chi
                    INSERT INTO pcb_hop_dong_duoc_cap (grantedcontract_id, auto_id, currency, referencenumber,
                        role, encryptedficode, typeoffinancing, contractphase,
                        startingdate, dateoflastupdate, cbcontractcode, profiles,

                        endDateOfContract, guarantedAmountFromGuarantor, personalGuaranteeAmount,
                        nrOfDaysOfPaymentDelay, worstStatus, dateWorstStatus,
                        maxNrOfDaysOfPaymentDelay, reorganizedCredit, amountOfTheCredits,
                        dateMaxNrOfDaysOfPaymentDelay)
                    SELECT ctr.cis_no||'-TC' grantedcontract_id,
                       SEQ_PCB_HOP_DONG_DUOC_CAP.NEXTVAL auto_id, currency, referencenumber,
                        role, encryptedficode, typeoffinancing, contractphase,
                        TO_DATE(startingdate,'dd/mm/yyyy'), TO_DATE(dateoflastupdate,'dd/mm/yyyy'), cbcontractcode,cbContractCode||'-'||ctr.cis_no profiles,
                        --
                        TO_DATE(endDateOfContract,'dd/mm/yyyy'), guarantedAmountFromGuarantor,personalGuaranteeAmount ,
                        nrOfDaysOfPaymentDelay, worstStatus, TO_DATE(dateWorstStatus,'dd/mm/yyyy'),
                        maxNrOfDaysOfPaymentDelay, reorganizedCredit, amountOfTheCredits,
                        TO_DATE(dateMaxNrOfDaysOfPaymentDelay,'dd/mm/yyyy')
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rIReqOutput.creditHistory.contract.nonInstalments.grantedContract[*]'
                        COLUMNS
                            (
                            currency VARCHAR2(200) PATH '$.commonData.currency',
                            referenceNumber VARCHAR2(200) PATH '$.commonData.referenceNumber',
                            role VARCHAR2(200) PATH '$.commonData.role',
                            encryptedFICode VARCHAR2(200) PATH '$.commonData.encryptedFICode',
                            typeOfFinancing VARCHAR2(200) PATH '$.commonData.typeOfFinancing',
                            contractPhase VARCHAR2(200) PATH '$.commonData.contractPhase',
                            startingDate VARCHAR2(200) PATH '$.commonData.startingDate',
                            dateOfLastUpdate VARCHAR2(200) PATH '$.commonData.dateOfLastUpdate',
                            cbContractCode VARCHAR2(200) PATH '$.commonData.cbContractCode',
                            --
                            endDateOfContract VARCHAR2(200) PATH '$.endDateOfContract',
                            guarantedAmountFromGuarantor VARCHAR2(200) PATH '$.guarantedAmountFromGuarantor',
                            personalGuaranteeAmount VARCHAR2(200) PATH '$.personalGuaranteeAmount',
                            nrOfDaysOfPaymentDelay VARCHAR2(200) PATH '$.nrOfDaysOfPaymentDelay',
                            worstStatus VARCHAR2(200) PATH '$.worstStatus',
                            dateWorstStatus VARCHAR2(200) PATH '$.dateWorstStatus',
                            maxNrOfDaysOfPaymentDelay VARCHAR2(200) PATH '$.maxNrOfDaysOfPaymentDelay',
                            reorganizedCredit VARCHAR2(200) PATH '$.reorganizedCredit',
                            amountOfTheCredits VARCHAR2(200) PATH '$.amountOfTheCredits',
                            dateMaxNrOfDaysOfPaymentDelay VARCHAR2(200) PATH '$.dateMaxNrOfDaysOfPaymentDelay'
                            )) AS js
                    ) a;

                    --insert hop dong duoc cap detail thau chi
                    INSERT INTO pcb_hop_dong_duoc_cap_dtl (profiles_id, auto_id,
                        referenceyear, referencemonth, status, granted,
                        utilization, guarantedAmount)
                    SELECT cbContractCode||'-'||ctr.cis_no profiles_id, seq_pcb_hop_dong_duoc_cap_dtl.NEXTVAL auto_id,
                        referenceyear, referencemonth, status, granted,
                        utilization, guarantedAmount
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rIReqOutput.creditHistory.contract.nonInstalments.grantedContract[*]'
                        COLUMNS
                            (
                            cbContractCode PATH '$.commonData.cbContractCode',
                            NESTED PATH '$.profiles[*]'
                                COLUMNS (
                                referenceYear  PATH '$.referenceYear',
                                referenceMonth PATH '$.referenceMonth',
                                status PATH '$.status',
                                granted PATH '$.granted',
                                utilization PATH '$.utilization',
                                guarantedAmount PATH '$.guarantedAmount')
                            )) AS js
                    ) a;

                    --insert the
                    INSERT INTO pcb_the (response_id, cis_no, id_the,
                        numberofliving, numberofrefused, numberofrenounced,
                        numberofterminated, ac_limitofcredit, ac_residualamount,
                        ac_overdueamount, g_limitofcredit, g_residualamount,
                        g_overdueamount)
                    SELECT ctr.id response_id, ctr.cis_no, ctr.cis_no||'-THE' id_the,
                        numberofliving, numberofrefused, numberofrenounced,
                        numberofterminated, ac_limitofcredit, ac_residualamount,
                        ac_overdueamount, g_limitofcredit, g_residualamount,
                        g_overdueamount
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rIReqOutput.creditHistory.contract.cards'
                        COLUMNS
                            (
                            numberOfLiving VARCHAR2(200) PATH '$.summary.numberOfLiving',
                            numberOfRefused VARCHAR2(200) PATH '$.summary.numberOfRefused',
                            numberOfRenounced VARCHAR2(200) PATH '$.summary.numberOfRenounced',
                            numberOfTerminated VARCHAR2(200) PATH '$.summary.numberOfTerminated',
                            ac_limitofcredit VARCHAR2(200) PATH '$.aCCardAmounts.limitOfCredit',
                            ac_residualamount VARCHAR2(200) PATH '$.aCCardAmounts.residualAmount',
                            ac_overdueamount VARCHAR2(200) PATH '$.aCCardAmounts.overDueAmount',
                            g_limitofcredit VARCHAR2(200) PATH '$.gCardAmounts.limitOfCredit',
                            g_residualamount VARCHAR2(200) PATH '$.gCardAmounts.residualAmount',
                            g_overdueamount VARCHAR2(200) PATH '$.gCardAmounts.overDueAmount'
                            )) AS js
                    ) a;

                    --insert hop dong duoc cap - the
                    INSERT INTO pcb_hop_dong_duoc_cap (grantedcontract_id, auto_id, currency, referencenumber,
                        role, encryptedficode, typeoffinancing, contractphase,
                        startingdate, dateoflastupdate, cbcontractcode, profiles,
                        endDateOfContract,methodOfPayment,monthlyInstalmentAmount,
                        unpaidDueInstalmentsNumber,unpaidDueInstalmentsAmount,
                        maximumUnpaidAmount,guarantedAmountFromGuarantor,
                        personalGuaranteeAmount,maximumLevelOfDefault,
                        monthswithmaxlevelofdefault,nrOfDaysOfPaymentDelay,
                        worstStatus,dateWorstStatus ,maxNrOfDaysOfPaymentDelay ,
                        reorganizedCredit ,dateMaxNrOfDaysOfPaymentDelay ,
                        periodicity ,creditLimit ,typeOfInstalment ,
                        residualAmount ,maxResidualAmount ,dateOfMaximumResidualAmount ,
                        amountChargedInTheMonth ,maximumAmountChargedInTheMonth ,
                        amountOverTheLimit )
                    SELECT ctr.cis_no||'-THE' grantedcontract_id,
                       SEQ_PCB_HOP_DONG_DUOC_CAP.NEXTVAL auto_id, currency, referencenumber,
                        role, encryptedficode, typeoffinancing, contractphase,
                        TO_DATE(startingdate,'dd/mm/yyyy'), TO_DATE(dateoflastupdate,'dd/mm/yyyy'), cbcontractcode,cbContractCode||'-'||ctr.cis_no profiles,
                        TO_DATE(endDateOfContract,'dd/mm/yyyy') ,methodOfPayment,monthlyInstalmentAmount,
                        unpaidDueInstalmentsNumber,unpaidDueInstalmentsAmount,
                        maximumUnpaidAmount,guarantedAmountFromGuarantor,
                        personalGuaranteeAmount,maximumLevelOfDefault,
                        monthswithmaxlevelofdefault,nrOfDaysOfPaymentDelay,
                        worstStatus,TO_DATE(dateWorstStatus,'dd/mm/yyyy') ,maxNrOfDaysOfPaymentDelay ,
                        reorganizedCredit , TO_DATE(dateMaxNrOfDaysOfPaymentDelay,'dd/mm/yyyy') ,
                        periodicity ,creditLimit ,typeOfInstalment ,
                        residualAmount ,maxResidualAmount ,TO_DATE(dateOfMaximumResidualAmount,'dd/mm/yyyy') ,
                        amountChargedInTheMonth ,maximumAmountChargedInTheMonth ,
                        amountOverTheLimit
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rIReqOutput.creditHistory.contract.cards.grantedContract[*]'
                        COLUMNS
                            (currency VARCHAR2(20) PATH '$.commonData.currency',
                            referenceNumber VARCHAR2(20) PATH '$.commonData.referenceNumber',
                            role VARCHAR2(20) PATH '$.commonData.role',
                            encryptedFICode VARCHAR2(20) PATH '$.commonData.encryptedFICode',
                            typeOfFinancing VARCHAR2(20) PATH '$.commonData.typeOfFinancing',
                            contractPhase VARCHAR2(20) PATH '$.commonData.contractPhase',
                            startingDate VARCHAR2(20) PATH '$.commonData.startingDate',
                            dateOfLastUpdate VARCHAR2(20) PATH '$.commonData.dateOfLastUpdate',
                            cbContractCode VARCHAR2(20) PATH '$.commonData.cbContractCode',
                            --
                            endDateOfContract VARCHAR2(200) PATH '$.endDateOfContract',
                            methodOfPayment VARCHAR2(200) PATH '$.methodOfPayment',
                            monthlyInstalmentAmount VARCHAR2(200) PATH '$.monthlyInstalmentAmount',
                            unpaidDueInstalmentsNumber VARCHAR2(200) PATH '$.unpaidDueInstalmentsNumber',
                            unpaidDueInstalmentsAmount VARCHAR2(200) PATH '$.unpaidDueInstalmentsAmount',
                            maximumUnpaidAmount VARCHAR2(200) PATH '$.maximumUnpaidAmount',
                            guarantedAmountFromGuarantor VARCHAR2(200) PATH '$.guarantedAmountFromGuarantor',
                            personalGuaranteeAmount VARCHAR2(200) PATH '$.personalGuaranteeAmount',
                            maximumLevelOfDefault VARCHAR2(200) PATH '$.maximumLevelOfDefault',
                            monthswithmaxlevelofdefault VARCHAR2(200) PATH '$.numberOfMonthsWithMaximumLevelOfDefault',
                            nrOfDaysOfPaymentDelay VARCHAR2(200) PATH '$.nrOfDaysOfPaymentDelay',
                            worstStatus VARCHAR2(200) PATH '$.worstStatus',
                            dateWorstStatus VARCHAR2(200) PATH '$.dateWorstStatus',
                            maxNrOfDaysOfPaymentDelay VARCHAR2(200) PATH '$.maxNrOfDaysOfPaymentDelay',
                            reorganizedCredit VARCHAR2(200) PATH '$.reorganizedCredit',
                            dateMaxNrOfDaysOfPaymentDelay VARCHAR2(200) PATH '$.dateMaxNrOfDaysOfPaymentDelay',
                            periodicity VARCHAR2(200) PATH '$.periodicity',
                            creditLimit VARCHAR2(200) PATH '$.creditLimit',
                            typeOfInstalment VARCHAR2(200) PATH '$.typeOfInstalment',
                            residualAmount VARCHAR2(200) PATH '$.residualAmount',
                            maxResidualAmount VARCHAR2(200) PATH '$.maxResidualAmount',
                            dateOfMaximumResidualAmount VARCHAR2(200) PATH '$.dateOfMaximumResidualAmount',
                            amountChargedInTheMonth VARCHAR2(200) PATH '$.amountChargedInTheMonth',
                            maximumAmountChargedInTheMonth VARCHAR2(200) PATH '$.maximumAmountChargedInTheMonth',
                            amountOverTheLimit VARCHAR2(200) PATH '$.amountOverTheLimit'
                            )) AS js
                    ) a;

                    --insert hop dong duoc cap detail the
                    INSERT INTO pcb_hop_dong_duoc_cap_dtl (profiles_id, auto_id,
                        referenceyear, referencemonth, status, utilization,
                        residualAmount, default_dtl)
                    SELECT cbContractCode||'-'||ctr.cis_no profiles_id, seq_pcb_hop_dong_duoc_cap_dtl.NEXTVAL auto_id,
                        referenceyear, referencemonth, status, utilization,
                        residualAmount, vdefault default_dtl
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rIReqOutput.creditHistory.contract.cards.grantedContract[*]'
                        COLUMNS
                            (
                            cbContractCode PATH '$.commonData.cbContractCode',
                            NESTED PATH '$.profiles[*]'
                                COLUMNS (
                                referenceYear  PATH '$.referenceYear',
                                referenceMonth PATH '$.referenceMonth',
                                status PATH '$.status',
                                utilization PATH '$.utilization',
                                residualAmount PATH '$.residualAmount',
                                vdefault PATH '$.default')
                            )) AS js
                    ) a;

                    --insert hop dong ko duoc cap the
                    INSERT INTO pcb_hop_dong_khong_duoc_cap (notgrantedcontract_id,
                       auto_id, contractphase,
                       typeoffinancing, role, referencenumber, encryptedficode,
                       requestdateofthecontract, paymentPeriodicity,
                       monthlyInstalmentAmount, creditLimit, cbcontractcode)
                    SELECT ctr.cis_no||'-THE' notgrantedcontract_id,
                       SEQ_PCB_HOP_DONG_DUOC_CAP.NEXTVAL auto_id,contractphase,
                       typeoffinancing, role, referencenumber, encryptedficode,
                       TO_DATE(requestdateofthecontract,'dd/mm/yyyy'), paymentPeriodicity,
                       monthlyInstalmentAmount, creditLimit, cbcontractcode
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rIReqOutput.creditHistory.contract.cards.notGrantedContract[*]'
                            COLUMNS
                                (contractPhase VARCHAR2(20) PATH '$.contractPhase',
                                typeOfFinancing VARCHAR2(20) PATH '$.typeOfFinancing',
                                role VARCHAR2(500) PATH '$.role',
                                referenceNumber VARCHAR2(500) PATH '$.referenceNumber',
                                encryptedFICode VARCHAR2(500) PATH '$.encryptedFICode',
                                requestDateOfTheContract VARCHAR2(500) PATH '$.amounts.requestDateOfTheContract',
                                paymentPeriodicity  VARCHAR2(500) PATH '$.amounts.paymentPeriodicity',
                                monthlyInstalmentAmount  VARCHAR2(500) PATH '$.amounts.monthlyInstalmentAmount',
                                creditLimit  VARCHAR2(500) PATH '$.amounts.creditLimit',
                                cbContractCode VARCHAR2(500) PATH '$.cbContractCode'
                                )) AS js
                    ) a;
                ELSE --'rCReqOutput'
                	--inset bang tt chung
                    INSERT INTO PCB_TT_CHUNG (response_id, cis_no, cbsubjectcode, fisubjectcode,
                        name, gender, dateofbirth, countryofbirth,
                        main_address, main_additional, document_type,
                        document_number, document_dateissued, idcard, tin,
                        person_historicaladdress, person_reference)
                    SELECT ctr.id response_id, ctr.cis_no, a.cbsubjectcode, a.fisubjectcode,
                        a.name, a.gender, TO_DATE(a.dateofbirth,'dd/mm/yyyy') dateofbirth, a.countryofbirth,
                        a.main_address, a.main_additional, a.document_type,
                        a.document_number,TO_DATE(a.document_dateissued,'dd/mm/yyyy') document_dateissued, a.idcard, tin,
                        a.idcard person_historicaladdress,a.idcard person_reference
                    FROM
                    (SELECT JS.*
                    FROM JSON_TABLE(ctr.response_data, '$.rCReqOutput.subject.matched'
                        COLUMNS
                            (cbSubjectCode VARCHAR2(20) PATH '$.cbSubjectCode',
                            fiSubjectCode VARCHAR2(20) PATH '$.fiSubjectCode',
                            name VARCHAR2(500) PATH '$.person.name',
                            gender VARCHAR2(500) PATH '$.person.gender',
                            dateOfBirth VARCHAR2(500) PATH '$.person.dateOfBirth',
                            countryOfBirth VARCHAR2(500) PATH '$.person.countryOfBirth',
                            MAIN_ADDRESS  VARCHAR2(500) PATH '$.person.address.main.fullAddress',
                            MAIN_ADDITIONAL  VARCHAR2(500) PATH '$.person.address.additional.fullAddress',
                            DOCUMENT_TYPE  VARCHAR2(500) PATH '$.person.document.type',
                            DOCUMENT_NUMBER  VARCHAR2(500) PATH '$.person.document.number',
                            DOCUMENT_DATEISSUED  VARCHAR2(500) PATH '$.person.document.dateIssued',
                            idCard  VARCHAR2(500) PATH '$.person.idCard',
                            tin  VARCHAR2(500) PATH '$.person.tin'
                            )) AS js
                    ) a ;
					/*Datnd15 update code start*/
	                   v_result_document := CIS_OPS_NCB.PCK_SERVICE_NCB.RUN_TEST(ctr.CIS_NO);
	                   IF v_result_document IS NOT NULL THEN
		                   SELECT 	REGEXP_SUBSTR(v_result_document, '[^@]+', 1, 1),
						       		REGEXP_SUBSTR(v_result_document, '[^@]+', 1, 2)
						   INTO doc_type,doc_number
						   FROM dual;
						  UPDATE PCB_TT_CHUNG SET DOCUMENT_TYPE = doc_type , DOCUMENT_NUMBER =doc_number WHERE PCB_TT_CHUNG.CIS_NO = ctr.CIS_NO;
					   END IF;
					  /*Datnd15 update code END*/
                    --insert  bang tt chung reference
                    INSERT INTO pcb_tt_chung_reference (auto_id, cis_no, reference_id, type, ref_number)
                    SELECT seq_pcb_tt_chung_dtl.NEXTVAL, ctr.cis_no, idCard,  TYPE, ref_number
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rCReqOutput.subject.matched.person'
                        COLUMNS
                            (
                            idCard PATH '$.idCard',
                            NESTED PATH '$.reference[*]'
                                COLUMNS (
                                type  PATH '$.type',
                                ref_number PATH '$.number')
                            )) AS js
                    ) a;

                    --insert  bang tt chung historicaladdress_main
                    INSERT INTO pcb_tt_chung_historicaladdress_main (auto_id ,historicaladdress_main_id,cis_no ,fulladdress)
                    SELECT seq_pcb_tt_chung_dtl.NEXTVAL, idCard , ctr.cis_no, fulladdress
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rCReqOutput.subject.matched.person'
                        COLUMNS
                            (
                            idCard PATH '$.idCard',
                            NESTED PATH '$.historicalAddress.main[*]'
                                COLUMNS (
                                fullAddress  PATH '$.fullAddress')
                            )) AS js
                    ) a;

                    --insert lich su the
                    INSERT INTO pcb_Credit_History (response_id, cis_no,
                        cbContractCode, typeOfFinancing, totalNumberOfContract,
                        numberOfReportingInstitution, worstRecentStatus, instalments_id,
                        nonInstalments_id, cards_id, currencyCode, percentage)
                    SELECT ctr.id response_id, ctr.cis_no,
                        cbContractCode, typeOfFinancing, totalNumberOfContract,
                        numberOfReportingInstitution, worstRecentStatus, ctr.cis_no,
                         ctr.cis_no,  ctr.cis_no, currencyCode, percentage
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rCReqOutput.creditHistory'
                        COLUMNS
                            (cbContractCode PATH '$.inquiredOperation.cbContractCode',
                            typeOfFinancing PATH '$.inquiredOperation.typeOfFinancing',
                            totalNumberOfContract PATH '$.generalData.totalNumberOfContract',
                            numberOfReportingInstitution PATH '$.generalData.numberOfReportingInstitution',
                            worstRecentStatus PATH '$.generalData.worstRecentStatus',
                            currencyCode PATH '$.currencySummary.currencyPercentage.currencyCode',
                            percentage PATH '$.currencySummary.currencyPercentage.percentage'
                            )) AS js
                    ) a;

                    --insert hop dong vay tt
                    INSERT INTO pcb_hop_dong_vay_tt (response_id, cis_no, id_tt, numberofliving, numberofrefused,
                       numberofrenounced, numberofterminated,
                       acinstamounts_monthly,
                       acinstamounts_remaining, acinstamounts_unpaiddue,
                       ginstamounts_monthly, ginstamounts_remaining,
                       ginstamounts_unpaiddue)
                    SELECT ctr.id response_id, ctr.cis_no, ctr.cis_no||'-TT', numberofliving, numberofrefused,
                       numberofrenounced, numberofterminated,
                       acinstamounts_monthly,
                       acinstamounts_remaining, acinstamounts_unpaiddue,
                       ginstamounts_monthly, ginstamounts_remaining,
                       ginstamounts_unpaiddue
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rCReqOutput.creditHistory.contract.instalments'
                        COLUMNS
                            (numberOfLiving VARCHAR2(20) PATH '$.summary.numberOfLiving',
                            numberOfRefused VARCHAR2(20) PATH '$.summary.numberOfRefused',
                            numberOfRenounced VARCHAR2(500) PATH '$.summary.numberOfRenounced',
                            numberOfTerminated VARCHAR2(500) PATH '$.summary.numberOfTerminated',
                            --
                            acinstamounts_monthly VARCHAR2(500) PATH '$.aCInstAmounts.monthlyInstalmentsAmount',
                            acinstamounts_remaining VARCHAR2(500) PATH '$.aCInstAmounts.remainingInstalmentsAmount',
                            acinstamounts_unpaiddue  VARCHAR2(500) PATH '$.aCInstAmounts.unpaidDueInstalmentsAmount',
                            ginstamounts_monthly  VARCHAR2(500) PATH '$.gInstAmounts.monthlyInstalmentsAmount',
                            ginstamounts_remaining  VARCHAR2(500) PATH '$.gInstAmounts.remainingInstalmentsAmount',
                            ginstamounts_unpaiddue  VARCHAR2(500) PATH '$.gInstAmounts.unpaidDueInstalmentsAmount'
                            )) AS js
                    ) a;

                    --insert hop dong duoc cap
                    INSERT INTO pcb_hop_dong_duoc_cap (grantedcontract_id, auto_id, currency, referencenumber,
                        role, encryptedficode, typeoffinancing, contractphase,
                        startingdate, dateoflastupdate, cbcontractcode, profiles,
                        endDateOfContract, methodOfPayment,totalNumberOfInstalments ,
                        paymentsPeriodicity,nextDueInstalmentAmount, totalAmount,
                        monthlyInstalmentAmount, remainingInstalmentsNumber,remainingInstalmentsAmount,
                        lastPaymentDate,unpaidDueInstalmentsNumber ,unpaidDueInstalmentsAmount,
                        maximumUnpaidAmount, guarantedAmountFromGuarantor, personalGuaranteeAmount,
                        maximumLevelOfDefault, monthswithmaxlevelofdefault, nrOfDaysOfPaymentDelay,
                        worstStatus,dateWorstStatus,maxNrOfDaysOfPaymentDelay,
                        reorganizedCredit,dateMaxNrOfDaysOfPaymentDelay)
                    SELECT ctr.cis_no||'-TT' grantedcontract_id,
                       SEQ_PCB_HOP_DONG_DUOC_CAP.NEXTVAL auto_id, currency, referencenumber,
                        role, encryptedficode, typeoffinancing, contractphase,
                        TO_DATE(startingdate,'dd/mm/yyyy'), TO_DATE(dateoflastupdate,'dd/mm/yyyy'), cbcontractcode,cbContractCode||'-'||ctr.cis_no profiles,
                        TO_DATE(endDateOfContract,'dd/mm/yyyy'), methodOfPayment,totalNumberOfInstalments ,
                        paymentsPeriodicity,nextDueInstalmentAmount, totalAmount,
                        monthlyInstalmentAmount, remainingInstalmentsNumber,remainingInstalmentsAmount,
                        TO_DATE(lastPaymentDate,'dd/mm/yyyy'),unpaidDueInstalmentsNumber ,unpaidDueInstalmentsAmount,
                        maximumUnpaidAmount, guarantedAmountFromGuarantor, personalGuaranteeAmount,
                        maximumLevelOfDefault, monthswithmaxlevelofdefault, nrOfDaysOfPaymentDelay,
                        worstStatus,TO_DATE(dateWorstStatus,'dd/mm/yyyy'),maxNrOfDaysOfPaymentDelay,
                        reorganizedCredit,TO_DATE(dateMaxNrOfDaysOfPaymentDelay,'dd/mm/yyyy')
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rCReqOutput.creditHistory.contract.instalments.grantedContract[*]'
                        COLUMNS
                            (currency VARCHAR2(20) PATH '$.commonData.currency',
                            referenceNumber VARCHAR2(20) PATH '$.commonData.referenceNumber',
                            role VARCHAR2(20) PATH '$.commonData.role',
                            encryptedFICode VARCHAR2(20) PATH '$.commonData.encryptedFICode',
                            typeOfFinancing VARCHAR2(20) PATH '$.commonData.typeOfFinancing',
                            contractPhase VARCHAR2(20) PATH '$.commonData.contractPhase',
                            startingDate VARCHAR2(20) PATH '$.commonData.startingDate',
                            dateOfLastUpdate VARCHAR2(20) PATH '$.commonData.dateOfLastUpdate',
                            cbContractCode VARCHAR2(20) PATH '$.commonData.cbContractCode',
                            endDateOfContract  VARCHAR2(200) PATH '$.endDateOfContract',
                            methodOfPayment  VARCHAR2(200) PATH '$.methodOfPayment',
                            totalNumberOfInstalments VARCHAR2(200) PATH '$.totalNumberOfInstalments',
                            paymentsPeriodicity VARCHAR2(200) PATH '$.paymentsPeriodicity',
                            nextDueInstalmentAmount VARCHAR2(200) PATH '$.nextDueInstalmentAmount',
                            totalAmount VARCHAR2(200) PATH '$.totalAmount',
                            monthlyInstalmentAmount VARCHAR2(200) PATH '$.monthlyInstalmentAmount',
                            remainingInstalmentsNumber VARCHAR2(200) PATH '$.remainingInstalmentsNumber',
                            remainingInstalmentsAmount VARCHAR2(200) PATH '$.remainingInstalmentsAmount',
                            lastPaymentDate VARCHAR2(200) PATH '$.lastPaymentDate',
                            unpaidDueInstalmentsNumber VARCHAR2(200) PATH '$.unpaidDueInstalmentsNumber',
                            unpaidDueInstalmentsAmount VARCHAR2(200) PATH '$.unpaidDueInstalmentsAmount',
                            maximumUnpaidAmount VARCHAR2(200) PATH '$.maximumUnpaidAmount',
                            guarantedAmountFromGuarantor VARCHAR2(200) PATH '$.guarantedAmountFromGuarantor',
                            personalGuaranteeAmount VARCHAR2(200) PATH '$.personalGuaranteeAmount',
                            maximumLevelOfDefault VARCHAR2(200) PATH '$.maximumLevelOfDefault',
                            monthswithmaxlevelofdefault VARCHAR2(200) PATH '$.numberOfMonthsWithMaximumLevelOfDefault',
                            nrOfDaysOfPaymentDelay VARCHAR2(200) PATH '$.nrOfDaysOfPaymentDelay',
                            worstStatus VARCHAR2(200) PATH '$.worstStatus',
                            dateWorstStatus VARCHAR2(200) PATH '$.dateWorstStatus',
                            maxNrOfDaysOfPaymentDelay VARCHAR2(200) PATH '$.maxNrOfDaysOfPaymentDelay',
                            reorganizedCredit VARCHAR2(200) PATH '$.reorganizedCredit',
                            dateMaxNrOfDaysOfPaymentDelay VARCHAR2(200) PATH '$.dateMaxNrOfDaysOfPaymentDelay'
                                )) AS js
                    ) a;


                    --insert hop dong khong duoc cap
                    INSERT INTO pcb_hop_dong_khong_duoc_cap (notgrantedcontract_id,
                       auto_id, contractphase,
                       typeoffinancing, role, referencenumber, encryptedficode,
                       requestdateofthecontract, totalnumberofinstalments,
                       paymentperiodicity, totalamount, monthlyinstalmentamount,
                       cbcontractcode)
                    SELECT ctr.cis_no||'-TT' notgrantedcontract_id,
                       SEQ_PCB_HOP_DONG_DUOC_CAP.NEXTVAL auto_id,contractphase,
                       typeoffinancing, role, referencenumber, encryptedficode,
                       TO_DATE(requestdateofthecontract,'dd/mm/yyyy'), totalnumberofinstalments,
                       paymentperiodicity, totalamount, monthlyinstalmentamount,
                       cbcontractcode
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rCReqOutput.creditHistory.contract.instalments.notGrantedContract[*]'
                            COLUMNS
                                (contractPhase VARCHAR2(20) PATH '$.contractPhase',
                                typeOfFinancing VARCHAR2(20) PATH '$.typeOfFinancing',
                                role VARCHAR2(500) PATH '$.role',
                                referenceNumber VARCHAR2(500) PATH '$.referenceNumber',
                                encryptedFICode VARCHAR2(500) PATH '$.encryptedFICode',
                                requestDateOfTheContract VARCHAR2(500) PATH '$.amounts.requestDateOfTheContract',
                                totalNumberOfInstalments  VARCHAR2(500) PATH '$.amounts.totalNumberOfInstalments',
                                paymentPeriodicity  VARCHAR2(500) PATH '$.amounts.paymentPeriodicity',
                                totalAmount  VARCHAR2(500) PATH '$.amounts.totalAmount',
                                monthlyInstalmentAmount  VARCHAR2(500) PATH '$.amounts.monthlyInstalmentAmount',
                                cbContractCode VARCHAR2(500) PATH '$.cbContractCode'
                                )) AS js
                    ) a;

                    --insert hop dong duoc cap detail
                    INSERT INTO pcb_hop_dong_duoc_cap_dtl (profiles_id, auto_id,
                        referenceyear, referencemonth, status, default_dtl)
                    SELECT cbContractCode||'-'||ctr.cis_no profiles_id, seq_pcb_hop_dong_duoc_cap_dtl.NEXTVAL auto_id,
                        referenceyear, referencemonth, status, vdefault default_dtl
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rCReqOutput.creditHistory.contract.instalments.grantedContract[*]'
                        COLUMNS
                            (
                            cbContractCode PATH '$.commonData.cbContractCode',
                            NESTED PATH '$.profiles[*]'
                                COLUMNS (
                                referenceYear  PATH '$.referenceYear',
                                referenceMonth PATH '$.referenceMonth',
                                status PATH '$.status',
                                vdefault PATH '$.default')
                            )) AS js
                    ) a;

                    --insert hop dong thau chi
                    INSERT INTO pcb_hop_dong_vay_tc ( response_id, cis_no, id_tc, numberofliving, numberofrefused,
                        numberofrenounced, numberofterminated,
                        acno_creditlimit, acno_utilization, acno_overdraft,
                        gno_creditlimit, gno_utilization, gno_overdraft)
                    SELECT ctr.id, ctr.cis_no, ctr.cis_no||'-TC' id_tc,numberofliving, numberofrefused,
                        numberofrenounced, numberofterminated,
                        acno_creditlimit, acno_utilization, acno_overdraft,
                        gno_creditlimit, gno_utilization, gno_overdraft
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rCReqOutput.creditHistory.contract.nonInstalments[*]'
                        COLUMNS
                            (
                            numberOfLiving VARCHAR2(200) PATH '$.summary.numberOfLiving',
                            numberOfRefused VARCHAR2(200) PATH '$.summary.numberOfRefused',
                            numberOfRenounced VARCHAR2(200) PATH '$.summary.numberOfRenounced',
                            numberOfTerminated VARCHAR2(200) PATH '$.summary.numberOfTerminated',
                            acno_creditlimit VARCHAR2(200) PATH '$.aCNoInstAmounts.creditLimit',
                            acno_utilization VARCHAR2(200) PATH '$.aCNoInstAmounts.utilization',
                            acno_overdraft VARCHAR2(200) PATH '$.aCNoInstAmounts.overdraft',
                            gno_creditlimit VARCHAR2(200) PATH '$.gNoInstAmounts.creditLimit',
                            gno_utilization VARCHAR2(200) PATH '$.gNoInstAmounts.utilization',
                            gno_overdraft VARCHAR2(200) PATH '$.gNoInstAmounts.overdraft'
                            )) AS js
                    ) a;

                    --insert hop dong ko duoc cap thau chi
                    INSERT INTO pcb_hop_dong_khong_duoc_cap (notgrantedcontract_id,
                       auto_id, contractphase,
                       typeoffinancing, role, referencenumber, encryptedficode,
                       requestdateofthecontract, totalAmount, cbcontractcode)
                    SELECT ctr.cis_no||'-TC' notgrantedcontract_id,
                       SEQ_PCB_HOP_DONG_DUOC_CAP.NEXTVAL auto_id,contractphase,
                       typeoffinancing, role, referencenumber, encryptedficode,
                       TO_DATE(requestdateofthecontract,'dd/mm/yyyy'), totalAmount,
                       cbcontractcode
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rCReqOutput.creditHistory.contract.nonInstalments.notGrantedContract[*]'
                            COLUMNS
                                (contractPhase VARCHAR2(20) PATH '$.contractPhase',
                                typeOfFinancing VARCHAR2(20) PATH '$.typeOfFinancing',
                                role VARCHAR2(500) PATH '$.role',
                                referenceNumber VARCHAR2(500) PATH '$.referenceNumber',
                                encryptedFICode VARCHAR2(500) PATH '$.encryptedFICode',
                                requestDateOfTheContract VARCHAR2(500) PATH '$.amounts.requestDateOfTheContract',
                                totalAmount  VARCHAR2(500) PATH '$.amounts.totalAmount',
                                cbContractCode VARCHAR2(500) PATH '$.cbContractCode'
                                )) AS js
                    ) a;

                    --insert hop dong duoc cap thau chi
                    INSERT INTO pcb_hop_dong_duoc_cap (grantedcontract_id, auto_id, currency, referencenumber,
                        role, encryptedficode, typeoffinancing, contractphase,
                        startingdate, dateoflastupdate, cbcontractcode, profiles,

                        endDateOfContract, guarantedAmountFromGuarantor, personalGuaranteeAmount,
                        nrOfDaysOfPaymentDelay, worstStatus, dateWorstStatus,
                        maxNrOfDaysOfPaymentDelay, reorganizedCredit, amountOfTheCredits,
                        dateMaxNrOfDaysOfPaymentDelay)
                    SELECT ctr.cis_no||'-TC' grantedcontract_id,
                       SEQ_PCB_HOP_DONG_DUOC_CAP.NEXTVAL auto_id, currency, referencenumber,
                        role, encryptedficode, typeoffinancing, contractphase,
                        TO_DATE(startingdate,'dd/mm/yyyy'), TO_DATE(dateoflastupdate,'dd/mm/yyyy'), cbcontractcode,cbContractCode||'-'||ctr.cis_no profiles,
                        --
                        TO_DATE(endDateOfContract,'dd/mm/yyyy'), guarantedAmountFromGuarantor,personalGuaranteeAmount ,
                        nrOfDaysOfPaymentDelay, worstStatus, TO_DATE(dateWorstStatus,'dd/mm/yyyy'),
                        maxNrOfDaysOfPaymentDelay, reorganizedCredit, amountOfTheCredits,
                        TO_DATE(dateMaxNrOfDaysOfPaymentDelay,'dd/mm/yyyy')
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rCReqOutput.creditHistory.contract.nonInstalments.grantedContract[*]'
                        COLUMNS
                            (
                            currency VARCHAR2(200) PATH '$.commonData.currency',
                            referenceNumber VARCHAR2(200) PATH '$.commonData.referenceNumber',
                            role VARCHAR2(200) PATH '$.commonData.role',
                            encryptedFICode VARCHAR2(200) PATH '$.commonData.encryptedFICode',
                            typeOfFinancing VARCHAR2(200) PATH '$.commonData.typeOfFinancing',
                            contractPhase VARCHAR2(200) PATH '$.commonData.contractPhase',
                            startingDate VARCHAR2(200) PATH '$.commonData.startingDate',
                            dateOfLastUpdate VARCHAR2(200) PATH '$.commonData.dateOfLastUpdate',
                            cbContractCode VARCHAR2(200) PATH '$.commonData.cbContractCode',
                            --
                            endDateOfContract VARCHAR2(200) PATH '$.endDateOfContract',
                            guarantedAmountFromGuarantor VARCHAR2(200) PATH '$.guarantedAmountFromGuarantor',
                            personalGuaranteeAmount VARCHAR2(200) PATH '$.personalGuaranteeAmount',
                            nrOfDaysOfPaymentDelay VARCHAR2(200) PATH '$.nrOfDaysOfPaymentDelay',
                            worstStatus VARCHAR2(200) PATH '$.worstStatus',
                            dateWorstStatus VARCHAR2(200) PATH '$.dateWorstStatus',
                            maxNrOfDaysOfPaymentDelay VARCHAR2(200) PATH '$.maxNrOfDaysOfPaymentDelay',
                            reorganizedCredit VARCHAR2(200) PATH '$.reorganizedCredit',
                            amountOfTheCredits VARCHAR2(200) PATH '$.amountOfTheCredits',
                            dateMaxNrOfDaysOfPaymentDelay VARCHAR2(200) PATH '$.dateMaxNrOfDaysOfPaymentDelay'
                            )) AS js
                    ) a;

                    --insert hop dong duoc cap detail thau chi
                    INSERT INTO pcb_hop_dong_duoc_cap_dtl (profiles_id, auto_id,
                        referenceyear, referencemonth, status, granted,
                        utilization, guarantedAmount)
                    SELECT cbContractCode||'-'||ctr.cis_no profiles_id, seq_pcb_hop_dong_duoc_cap_dtl.NEXTVAL auto_id,
                        referenceyear, referencemonth, status, granted,
                        utilization, guarantedAmount
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rCReqOutput.creditHistory.contract.nonInstalments.grantedContract[*]'
                        COLUMNS
                            (
                            cbContractCode PATH '$.commonData.cbContractCode',
                            NESTED PATH '$.profiles[*]'
                                COLUMNS (
                                referenceYear  PATH '$.referenceYear',
                                referenceMonth PATH '$.referenceMonth',
                                status PATH '$.status',
                                granted PATH '$.granted',
                                utilization PATH '$.utilization',
                                guarantedAmount PATH '$.guarantedAmount')
                            )) AS js
                    ) a;

                    --insert the
                    INSERT INTO pcb_the (response_id, cis_no, id_the,
                        numberofliving, numberofrefused, numberofrenounced,
                        numberofterminated, ac_limitofcredit, ac_residualamount,
                        ac_overdueamount, g_limitofcredit, g_residualamount,
                        g_overdueamount)
                    SELECT ctr.id response_id, ctr.cis_no, ctr.cis_no||'-THE' id_the,
                        numberofliving, numberofrefused, numberofrenounced,
                        numberofterminated, ac_limitofcredit, ac_residualamount,
                        ac_overdueamount, g_limitofcredit, g_residualamount,
                        g_overdueamount
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rCReqOutput.creditHistory.contract.cards'
                        COLUMNS
                            (
                            numberOfLiving VARCHAR2(200) PATH '$.summary.numberOfLiving',
                            numberOfRefused VARCHAR2(200) PATH '$.summary.numberOfRefused',
                            numberOfRenounced VARCHAR2(200) PATH '$.summary.numberOfRenounced',
                            numberOfTerminated VARCHAR2(200) PATH '$.summary.numberOfTerminated',
                            ac_limitofcredit VARCHAR2(200) PATH '$.aCCardAmounts.limitOfCredit',
                            ac_residualamount VARCHAR2(200) PATH '$.aCCardAmounts.residualAmount',
                            ac_overdueamount VARCHAR2(200) PATH '$.aCCardAmounts.overDueAmount',
                            g_limitofcredit VARCHAR2(200) PATH '$.gCardAmounts.limitOfCredit',
                            g_residualamount VARCHAR2(200) PATH '$.gCardAmounts.residualAmount',
                            g_overdueamount VARCHAR2(200) PATH '$.gCardAmounts.overDueAmount'
                            )) AS js
                    ) a;

                    --insert hop dong duoc cap - the
                    INSERT INTO pcb_hop_dong_duoc_cap (grantedcontract_id, auto_id, currency, referencenumber,
                        role, encryptedficode, typeoffinancing, contractphase,
                        startingdate, dateoflastupdate, cbcontractcode, profiles,
                        endDateOfContract,methodOfPayment,monthlyInstalmentAmount,
                        unpaidDueInstalmentsNumber,unpaidDueInstalmentsAmount,
                        maximumUnpaidAmount,guarantedAmountFromGuarantor,
                        personalGuaranteeAmount,maximumLevelOfDefault,
                        monthswithmaxlevelofdefault,nrOfDaysOfPaymentDelay,
                        worstStatus,dateWorstStatus ,maxNrOfDaysOfPaymentDelay ,
                        reorganizedCredit ,dateMaxNrOfDaysOfPaymentDelay ,
                        periodicity ,creditLimit ,typeOfInstalment ,
                        residualAmount ,maxResidualAmount ,dateOfMaximumResidualAmount ,
                        amountChargedInTheMonth ,maximumAmountChargedInTheMonth ,
                        amountOverTheLimit )
                    SELECT ctr.cis_no||'-THE' grantedcontract_id,
                       SEQ_PCB_HOP_DONG_DUOC_CAP.NEXTVAL auto_id, currency, referencenumber,
                        role, encryptedficode, typeoffinancing, contractphase,
                        TO_DATE(startingdate,'dd/mm/yyyy'), TO_DATE(dateoflastupdate,'dd/mm/yyyy'), cbcontractcode,cbContractCode||'-'||ctr.cis_no profiles,
                        TO_DATE(endDateOfContract,'dd/mm/yyyy') ,methodOfPayment,monthlyInstalmentAmount,
                        unpaidDueInstalmentsNumber,unpaidDueInstalmentsAmount,
                        maximumUnpaidAmount,guarantedAmountFromGuarantor,
                        personalGuaranteeAmount,maximumLevelOfDefault,
                        monthswithmaxlevelofdefault,nrOfDaysOfPaymentDelay,
                        worstStatus,TO_DATE(dateWorstStatus,'dd/mm/yyyy') ,maxNrOfDaysOfPaymentDelay ,
                        reorganizedCredit , TO_DATE(dateMaxNrOfDaysOfPaymentDelay,'dd/mm/yyyy') ,
                        periodicity ,creditLimit ,typeOfInstalment ,
                        residualAmount ,maxResidualAmount ,TO_DATE(dateOfMaximumResidualAmount,'dd/mm/yyyy') ,
                        amountChargedInTheMonth ,maximumAmountChargedInTheMonth ,
                        amountOverTheLimit
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rCReqOutput.creditHistory.contract.cards.grantedContract[*]'
                        COLUMNS
                            (currency VARCHAR2(20) PATH '$.commonData.currency',
                            referenceNumber VARCHAR2(20) PATH '$.commonData.referenceNumber',
                            role VARCHAR2(20) PATH '$.commonData.role',
                            encryptedFICode VARCHAR2(20) PATH '$.commonData.encryptedFICode',
                            typeOfFinancing VARCHAR2(20) PATH '$.commonData.typeOfFinancing',
                            contractPhase VARCHAR2(20) PATH '$.commonData.contractPhase',
                            startingDate VARCHAR2(20) PATH '$.commonData.startingDate',
                            dateOfLastUpdate VARCHAR2(20) PATH '$.commonData.dateOfLastUpdate',
                            cbContractCode VARCHAR2(20) PATH '$.commonData.cbContractCode',
                            --
                            endDateOfContract VARCHAR2(200) PATH '$.endDateOfContract',
                            methodOfPayment VARCHAR2(200) PATH '$.methodOfPayment',
                            monthlyInstalmentAmount VARCHAR2(200) PATH '$.monthlyInstalmentAmount',
                            unpaidDueInstalmentsNumber VARCHAR2(200) PATH '$.unpaidDueInstalmentsNumber',
                            unpaidDueInstalmentsAmount VARCHAR2(200) PATH '$.unpaidDueInstalmentsAmount',
                            maximumUnpaidAmount VARCHAR2(200) PATH '$.maximumUnpaidAmount',
                            guarantedAmountFromGuarantor VARCHAR2(200) PATH '$.guarantedAmountFromGuarantor',
                            personalGuaranteeAmount VARCHAR2(200) PATH '$.personalGuaranteeAmount',
                            maximumLevelOfDefault VARCHAR2(200) PATH '$.maximumLevelOfDefault',
                            monthswithmaxlevelofdefault VARCHAR2(200) PATH '$.numberOfMonthsWithMaximumLevelOfDefault',
                            nrOfDaysOfPaymentDelay VARCHAR2(200) PATH '$.nrOfDaysOfPaymentDelay',
                            worstStatus VARCHAR2(200) PATH '$.worstStatus',
                            dateWorstStatus VARCHAR2(200) PATH '$.dateWorstStatus',
                            maxNrOfDaysOfPaymentDelay VARCHAR2(200) PATH '$.maxNrOfDaysOfPaymentDelay',
                            reorganizedCredit VARCHAR2(200) PATH '$.reorganizedCredit',
                            dateMaxNrOfDaysOfPaymentDelay VARCHAR2(200) PATH '$.dateMaxNrOfDaysOfPaymentDelay',
                            periodicity VARCHAR2(200) PATH '$.periodicity',
                            creditLimit VARCHAR2(200) PATH '$.creditLimit',
                            typeOfInstalment VARCHAR2(200) PATH '$.typeOfInstalment',
                            residualAmount VARCHAR2(200) PATH '$.residualAmount',
                            maxResidualAmount VARCHAR2(200) PATH '$.maxResidualAmount',
                            dateOfMaximumResidualAmount VARCHAR2(200) PATH '$.dateOfMaximumResidualAmount',
                            amountChargedInTheMonth VARCHAR2(200) PATH '$.amountChargedInTheMonth',
                            maximumAmountChargedInTheMonth VARCHAR2(200) PATH '$.maximumAmountChargedInTheMonth',
                            amountOverTheLimit VARCHAR2(200) PATH '$.amountOverTheLimit'
                            )) AS js
                    ) a;

                    --insert hop dong duoc cap detail the
                    INSERT INTO pcb_hop_dong_duoc_cap_dtl (profiles_id, auto_id,
                        referenceyear, referencemonth, status, utilization,
                        residualAmount, default_dtl)
                    SELECT cbContractCode||'-'||ctr.cis_no profiles_id, seq_pcb_hop_dong_duoc_cap_dtl.NEXTVAL auto_id,
                        referenceyear, referencemonth, status, utilization,
                        residualAmount, vdefault default_dtl
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rCReqOutput.creditHistory.contract.cards.grantedContract[*]'
                        COLUMNS
                            (
                            cbContractCode PATH '$.commonData.cbContractCode',
                            NESTED PATH '$.profiles[*]'
                                COLUMNS (
                                referenceYear  PATH '$.referenceYear',
                                referenceMonth PATH '$.referenceMonth',
                                status PATH '$.status',
                                utilization PATH '$.utilization',
                                residualAmount PATH '$.residualAmount',
                                vdefault PATH '$.default')
                            )) AS js
                    ) a;

                    --insert hop dong ko duoc cap the
                    INSERT INTO pcb_hop_dong_khong_duoc_cap (notgrantedcontract_id,
                       auto_id, contractphase,
                       typeoffinancing, role, referencenumber, encryptedficode,
                       requestdateofthecontract, paymentPeriodicity,
                       monthlyInstalmentAmount, creditLimit, cbcontractcode)
                    SELECT ctr.cis_no||'-THE' notgrantedcontract_id,
                       SEQ_PCB_HOP_DONG_DUOC_CAP.NEXTVAL auto_id,contractphase,
                       typeoffinancing, role, referencenumber, encryptedficode,
                       TO_DATE(requestdateofthecontract,'dd/mm/yyyy'), paymentPeriodicity,
                       monthlyInstalmentAmount, creditLimit, cbcontractcode
                    FROM
                    (
                        SELECT JS.*
                        FROM JSON_TABLE(ctr.response_data, '$.rCReqOutput.creditHistory.contract.cards.notGrantedContract[*]'
                            COLUMNS
                                (contractPhase VARCHAR2(20) PATH '$.contractPhase',
                                typeOfFinancing VARCHAR2(20) PATH '$.typeOfFinancing',
                                role VARCHAR2(500) PATH '$.role',
                                referenceNumber VARCHAR2(500) PATH '$.referenceNumber',
                                encryptedFICode VARCHAR2(500) PATH '$.encryptedFICode',
                                requestDateOfTheContract VARCHAR2(500) PATH '$.amounts.requestDateOfTheContract',
                                paymentPeriodicity  VARCHAR2(500) PATH '$.amounts.paymentPeriodicity',
                                monthlyInstalmentAmount  VARCHAR2(500) PATH '$.amounts.monthlyInstalmentAmount',
                                creditLimit  VARCHAR2(500) PATH '$.amounts.creditLimit',
                                cbContractCode VARCHAR2(500) PATH '$.cbContractCode'
                                )) AS js
                    ) a;
                END IF;

            END LOOP;
        END IF;
    END;

    PROCEDURE PR_BCTH (
        p_idcard VARCHAR2,
        p_type VARCHAR2,
        p_out OUT SYS_REFCURSOR
    ) AS
        vPcb NUMBER;
        vCic NUMBER;
        vProduct_code VARCHAR2(20);
        vTT_TRALOI VARCHAR2(20);
        vTHOIGIANTL DATE;
        vSONGAY_CHAM_TT NUMBER;
        vNHOM NUMBER;
        vNHOM1 NUMBER;
        vNHOM2 NUMBER;
        vNHOM3 NUMBER;
        vNHOM4 NUMBER;
        vNHOM5 NUMBER;
        vNHOM6 NUMBER;
        PLN_htai_loan NUMBER := 0;
        PLN_htai_the NUMBER := 0;
        PLN_traiphieu_DN NUMBER := 0;
        vMax_nhomno NUMBER := 0;
        vTongDN NUMBER :=0 ;
        vTyle NUMBER :=0 ;
        vDIEM VARCHAR2(20);
        vHANG VARCHAR2(20);
        vresponse_date DATE;
        vGIA_TRI_TSBD NUMBER :=0 ;
        vPD VARCHAR2(10);
        vsl_nh_tracuu NUMBER;--Số NH tra cứu thông tin tín dụng của KH (trong 1 năm gần nhất)
        vsl_cttc_tracuu NUMBER;--Số CTTC tra cứu thông tin tín dụng của KH (trong 1 năm gần nhất)
        vUTILIZATION NUMBER;
        vB NUMBER;
        vB1 NUMBER;
        vF NUMBER;
        vF1 NUMBER;
        vso_tien_phai_tt NUMBER;
        vngay_ky_hdtd NUMBER;
        vremainingInstalmentsAmount NUMBER;
        vguarantedAmountFromGuarantor NUMBER;
        vCREDITLIMIT NUMBER;
        vTongDN_PCB NUMBER;
        vTongDN_QH NUMBER;
    BEGIN
        SELECT MAX(cis_no) INTO vPcb FROM pcb_tt_chung a
        WHERE (a.idcard = p_idcard OR a.document_number = p_idcard)
            AND cis_no IN (SELECT cis_no FROM cis_request WHERE channel = 'PCB' AND status = 'RECEIVED');

        SELECT MAX(TRUNC(response_date)) INTO vresponse_date FROM cis_request WHERE channel = 'PCB' AND status = 'RECEIVED' AND cis_no = vPcb;

        SELECT SUM(UTILIZATION) INTO vUTILIZATION FROM pcb_hop_dong_duoc_cap_dtl
        WHERE (REFERENCEYEAR||REFERENCEMONTH) IN (
            SELECT MAX(REFERENCEYEAR||REFERENCEMONTH) FROM pcb_hop_dong_duoc_cap a
            JOIN pcb_hop_dong_duoc_cap_dtl b ON b.PROFILES_ID = a.PROFILES AND a.guarantedAmountFromGuarantor = 0
            WHERE a.GRANTEDCONTRACT_ID LIKE  vPcb||'-TC' AND a.CONTRACTPHASE = 'LV');

        SELECT COUNT(DISTINCT CASE WHEN INSTR(e.encryptedFICode,'B') > 0 THEN encryptedFICode END ),
                COUNT(DISTINCT CASE WHEN INSTR(e.encryptedFICode,'F') > 0 THEN encryptedFICode END )
            INTO vB, vF
        FROM  pcb_hop_dong_khong_duoc_cap e
        WHERE  e.NOTGRANTEDCONTRACT_ID LIKE vPcb||'-%'
            AND MONTHS_BETWEEN(vresponse_date,e.requestDateOfTheContract)  <= 12;

        SELECT COUNT(DISTINCT CASE WHEN INSTR(a.encryptedFICode,'B') > 0 THEN encryptedFICode END ),
                COUNT(DISTINCT CASE WHEN INSTR(a.encryptedFICode,'F') > 0 THEN encryptedFICode END )
            INTO vB1, vF1
        FROM pcb_hop_dong_duoc_cap a
        WHERE instr(a.GRANTEDCONTRACT_ID ,vPcb||'-')>0
        AND MONTHS_BETWEEN(vresponse_date,a.startingDate) <= 12 ;

        IF UPPER(p_type) = 'TN' THEN --the nhan
        	SELECT MAX(response_id) INTO vCic  FROM tbl_cis_thong_tin_chung a
            	WHERE (a.cmnd_hc = p_idcard OR a.giay_to_khac = p_idcard)
                AND response_id IN (SELECT id FROM cis_response
        							WHERE cis_no IN (SELECT cis_no
                                    				FROM cis_request
                                                    WHERE channel = 'CIC' AND status = 'RECEIVED'
                                                    	AND product_code IN ('S11A','S10A','R11A','R10A')));

            BEGIN
                SELECT TO_NUMBER(SO_NGAY_CHAM_TT) INTO vSONGAY_CHAM_TT FROM  TBL_CIS_TT_THANH_TOAN_THE
                WHERE response_id IN (SELECT MAX(response_id) FROM tbl_cis_thong_tin_chung a
                                            WHERE (a.cmnd_hc = p_idcard OR a.giay_to_khac = p_idcard)
                                        AND response_id IN (SELECT id FROM cis_response
                                                            WHERE cis_no IN (SELECT cis_no
                                                                            FROM cis_request
                                                                            WHERE channel = 'CIC' AND status = 'RECEIVED'
                                                                                AND product_code = 'R14'))
                                        );
            EXCEPTION
      			WHEN NO_DATA_FOUND THEN
        		vSONGAY_CHAM_TT := 0;
    		END;

            BEGIN
                SELECT SUM(GIA_TRI_TSBD) INTO vGIA_TRI_TSBD FROM  TBL_CIS_TSDB
                WHERE response_id IN (SELECT MAX(response_id) FROM tbl_cis_thong_tin_chung a
                                            WHERE (a.cmnd_hc = p_idcard OR a.giay_to_khac = p_idcard)
                                        AND response_id IN (SELECT id FROM cis_response
                                                            WHERE cis_no IN (SELECT cis_no
                                                                            FROM cis_request
                                                                            WHERE channel = 'CIC' AND status = 'RECEIVED'
                                                                                AND product_code = 'R21'))
                                        );
            EXCEPTION
      			WHEN NO_DATA_FOUND THEN
        		vGIA_TRI_TSBD := 0;
    		END;
        ELSE --phap nhan
        	SELECT MAX(response_id) INTO vCic  FROM tbl_cis_thong_tin_chung a
            	WHERE (a.DKKD = p_idcard OR a.mst = p_idcard)
                AND response_id IN (SELECT id FROM cis_response
        							WHERE cis_no IN (SELECT cis_no
                                    				FROM cis_request
                                                    WHERE channel = 'CIC' AND status = 'RECEIVED'
                                                    	AND product_code IN ('S11A','S10A','R11A','R10A')));

            BEGIN
                SELECT TO_NUMBER(SO_NGAY_CHAM_TT) INTO vSONGAY_CHAM_TT FROM  TBL_CIS_TT_THANH_TOAN_THE
                WHERE response_id IN (SELECT MAX(response_id) FROM tbl_cis_thong_tin_chung a
                                            WHERE (a.dkkd = p_idcard OR a.mst = p_idcard)
                                        AND response_id IN (SELECT id FROM cis_response
                                                            WHERE cis_no IN (SELECT cis_no
                                                                            FROM cis_request
                                                                            WHERE channel = 'CIC' AND status = 'RECEIVED'
                                                                                AND product_code = 'R14.DN'))
                                        );
    		EXCEPTION
      			WHEN NO_DATA_FOUND THEN
        		vSONGAY_CHAM_TT := 0;
    		END;

            BEGIN
                SELECT SUM(GIA_TRI_TSBD) INTO vGIA_TRI_TSBD FROM  TBL_CIS_TSDB
                WHERE response_id IN (SELECT MAX(response_id) FROM tbl_cis_thong_tin_chung a
                                            WHERE (a.cmnd_hc = p_idcard OR a.giay_to_khac = p_idcard)
                                        AND response_id IN (SELECT id FROM cis_response
                                                            WHERE cis_no IN (SELECT cis_no
                                                                            FROM cis_request
                                                                            WHERE channel = 'CIC' AND status = 'RECEIVED'
                                                                                AND product_code = 'R20'))
                                        );
            EXCEPTION
      			WHEN NO_DATA_FOUND THEN
        		vGIA_TRI_TSBD := 0;
    		END;
        END IF;

        IF vCic IS NOT NULL THEN
            SELECT product_code INTO vProduct_code FROM cis_response WHERE id = vCic;

            SELECT DECODE(TT_TRALOI,'1','ETC','NTC') INTO vTT_TRALOI
            FROM
            (SELECT extractvalue(a.column_value, '/*/*:TT_NGUOITRACUU/*:TT_TRALOI') TT_TRALOI
                FROM TABLE(XMLSequence(XMLTYPE.createxml(
                (SELECT response_data FROM CIS_RESPONSE cr WHERE cr.id = vCic)
                ).EXTRACT('/*:NOIDUNG_BANTLTIN'))) a);

            SELECT TRUNC(TO_DATE(THOIGIANTL,'yyyy/mm/dd hh24:Mi')) INTO vTHOIGIANTL
            FROM
                (SELECT extractvalue(a.column_value, '/*/*:TT_NGUOITRACUU/*:THOIGIANTL') THOIGIANTL
                FROM   TABLE(XMLSequence(XMLTYPE.createxml(
                (SELECT response_data FROM CIS_RESPONSE cr WHERE cr.id = vCic)
                ).EXTRACT('/*:NOIDUNG_BANTLTIN'))) a );
		END IF;

        IF vProduct_code IN ('R11A','R10A') THEN
            SELECT  NVL(SUM(NVL(NHOM1_VND, NHOM1_USD *24000)),0),
                NVL(SUM(NVL(NHOM2_VND, NHOM2_USD *24000)),0),
                NVL(SUM(NVL(NHOM3_VND, NHOM3_USD *24000)),0),
                NVL(SUM(NVL(NHOM4_VND, NHOM4_USD *24000)),0),
                NVL(SUM(NVL(NHOM5_VND, NHOM5_USD *24000)),0),
                NVL(SUM(NVL(NOXAU_KHAC_VND, NOXAU_KHAC_USD *24000)),0)
            	INTO vNHOM1, vNHOM2, vNHOM3, vNHOM4, vNHOM5, vNHOM6
            FROM TBL_CIS_CHI_TIET_LOAI_VAY a WHERE a.response_id = vCic;

            BEGIN
                SELECT COUNT( DISTINCT CASE WHEN SUBSTR(b.code,1,2) IN ('02','05') THEN b.code END)  OVER (PARTITION BY a.response_id) sl_nh_tracuu,--Số NH tra cứu thông tin tín dụng của KH (trong 1 năm gần nhất)
                    COUNT( DISTINCT CASE WHEN SUBSTR(b.code,1,2) NOT IN ('02','05') THEN b.code END)  OVER (PARTITION BY a.response_id) sl_cttc_tracuu--Số CTTC tra cứu thông tin tín dụng của KH (trong 1 năm gần nhất)
                    INTO vsl_nh_tracuu, vsl_cttc_tracuu
                FROM TBL_CIS_QUAN_HE_TIN_DUNG a
                JOIN CIS_TCTD b ON a.ma_tctd = b.ma_tctd
                WHERE a.RESPONSE_ID = vCic;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    vsl_nh_tracuu := 0;
                    vsl_cttc_tracuu := 0;
            END;

        ELSIF vProduct_code IN ('S11A','S10A') THEN
        	SELECT
            	SUM(DECODE(NHOM_NO,'01',NVL(du_no_vnd, du_no_usd *24000),0)),
                SUM(DECODE(NHOM_NO,'02',NVL(du_no_vnd, du_no_usd *24000),0)),
                SUM(DECODE(NHOM_NO,'03',NVL(du_no_vnd, du_no_usd *24000),0)),
                SUM(DECODE(NHOM_NO,'04',NVL(du_no_vnd, du_no_usd *24000),0)),
                SUM(DECODE(NHOM_NO,'05',NVL(du_no_vnd, du_no_usd *24000),0)),
                SUM(CASE WHEN NHOM_NO not in ('01','02','03','04','05') THEN TO_NUMBER(NVL(du_no_vnd, du_no_usd *24000)) ELSE 0 END)
            	INTO vNHOM1, vNHOM2, vNHOM3, vNHOM4, vNHOM5, vNHOM6
            FROM TBL_CIS_DU_NO_HIEN_THOI a WHERE a.response_id = vCic;

            SELECT MAX(NVL(so_tien_phai_tt,0)) INTO vso_tien_phai_tt
            FROM TBL_CIS_TT_THANH_TOAN_THE a WHERE a.response_id = vCic AND LOAI_THANH_TOAN = 'DUNO_THETD';

            SELECT vNHOM1 + vNHOM2+vNHOM3+vNHOM4+ vNHOM5+vNHOM6 + vso_tien_phai_tt,
            	ROUND((vNHOM2+vNHOM3+vNHOM4+vNHOM5+vNHOM6)/(vNHOM1 + vNHOM2+vNHOM3+vNHOM4+ vNHOM5+vNHOM6+vso_tien_phai_tt),2)
            	INTO vTongDN, vTyle
            FROM dual;

            SELECT DIEM, HANG/*, PD*/ INTO vDIEM, vHANG/*, vPD*/
            FROM
            (SELECT extractvalue(a.column_value, '/*/*:NOIDUNG/*:DIEMTD/*:DIEM') DIEM,
            	extractvalue(a.column_value, '/*/*:NOIDUNG/*:DIEMTD/*:HANG') HANG
                --extractvalue(a.column_value, '/*/*:NOIDUNG/*:DIEM_XHTD/*:DONG/*:PD') PD
            FROM TABLE(XMLSequence(XMLTYPE.createxml(
                (SELECT response_data FROM CIS_RESPONSE cr WHERE cr.id = vCic)
                ).EXTRACT('/*:NOIDUNG_BANTLTIN'))) a);

            BEGIN
                SELECT COUNT( DISTINCT CASE WHEN SUBSTR(b.code,1,2) IN ('02','05') THEN b.code END)  OVER (PARTITION BY a.response_id) sl_nh_tracuu,--Số NH tra cứu thông tin tín dụng của KH (trong 1 năm gần nhất)
                    COUNT( DISTINCT CASE WHEN SUBSTR(b.code,1,2) NOT IN ('02','05') THEN b.code END)  OVER (PARTITION BY a.response_id) sl_cttc_tracuu--Số CTTC tra cứu thông tin tín dụng của KH (trong 1 năm gần nhất)
                    INTO vsl_nh_tracuu, vsl_cttc_tracuu
                FROM TBL_CIS_TT_THANH_TOAN_THE a
                JOIN CIS_TCTD b ON a.ma_tctd = b.ma_tctd
                WHERE a.RESPONSE_ID = vCic;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    vsl_nh_tracuu := 0;
                    vsl_cttc_tracuu := 0;
            END;
        END IF;

        IF vNHOM5 > 0 OR vNHOM6 > 0 THEN
        	PLN_htai_loan := 5;
        ELSIF vNHOM4 > 0 THEN
        	PLN_htai_loan := 4;
        ELSIF vNHOM3 > 0 THEN
        	PLN_htai_loan := 3;
        ELSIF vNHOM2 > 0 THEN
        	PLN_htai_loan := 2;
        ELSE
        	PLN_htai_loan := 1;
        END IF;

    
--        IF vProduct_code IN ('R10A','S10A') THEN
--        	SELECT nhomno INTO PLN_traiphieu_DN FROM TBL_CIS_QUAN_HE_TIN_DUNG
--            WHERE loai_quan_he = 'TRAIPHIEU'
--            AND response_id = vCic;
--        END IF;
        BEGIN
            SELECT nhomno INTO PLN_traiphieu_DN FROM TBL_CIS_QUAN_HE_TIN_DUNG
            WHERE loai_quan_he = 'TRAIPHIEU'
            AND response_id = vCic;
        EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    PLN_traiphieu_DN := 0;
        END;

        IF vSONGAY_CHAM_TT >= 0 AND vSONGAY_CHAM_TT <= 9 THEN
        	PLN_htai_the :=1;
        ELSIF vSONGAY_CHAM_TT >= 10 AND vSONGAY_CHAM_TT <= 90 THEN
        	PLN_htai_the :=2;
        ELSIF vSONGAY_CHAM_TT >= 91 AND vSONGAY_CHAM_TT <= 180 THEN
        	PLN_htai_the :=3;
        ELSIF vSONGAY_CHAM_TT >= 181 AND vSONGAY_CHAM_TT <= 360 THEN
        	PLN_htai_the :=4;
		ELSE
        	PLN_htai_the :=5;
        END IF;

        IF PLN_htai_loan >= PLN_htai_the AND PLN_htai_loan >= PLN_traiphieu_DN THEN
        	vMax_nhomno := PLN_htai_loan;
        ELSIF PLN_htai_the >= PLN_htai_loan AND PLN_htai_the >= PLN_traiphieu_DN THEN
        	vMax_nhomno := PLN_htai_the;
        ELSIF PLN_traiphieu_DN >= PLN_htai_loan AND PLN_traiphieu_DN >= PLN_htai_the THEN
        	vMax_nhomno := 0;
        END IF;
        

        BEGIN
            SELECT ROUND(MONTHS_BETWEEN(vTHOIGIANTL,MIN(TO_DATE(ngay_ky_hdtd,'yyyymmdd')) )) INTO vngay_ky_hdtd FROM TBL_CIS_TT_TONG_HOP_KHAC_HDTD WHERE response_id = vCic;
        EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    vngay_ky_hdtd := 0;
        END;

        SELECT SUM(CASE WHEN a.GRANTEDCONTRACT_ID = vPcb||'-TT' AND a.CONTRACTPHASE = 'LV' AND a.guarantedAmountFromGuarantor > 0 THEN a.remainingInstalmentsAmount ELSE 0 END) ,
            SUM(CASE WHEN a.guarantedAmountFromGuarantor > 0 THEN a.guarantedAmountFromGuarantor ELSE 0 END) ,
            SUM(CASE WHEN a.GRANTEDCONTRACT_ID = vPcb||'-THE' AND a.CONTRACTPHASE = 'LV' THEN a.CREDITLIMIT ELSE 0 END),
            SUM(CASE WHEN a.GRANTEDCONTRACT_ID = vPcb||'-THE' THEN a.residualAmount ELSE 0 END),
            SUM(CASE WHEN GRANTEDCONTRACT_ID = '-TT' THEN unpaidDueInstalmentsAmount ELSE 0 END)
            INTO vremainingInstalmentsAmount, vguarantedAmountFromGuarantor, vCREDITLIMIT, vTongDN_PCB, vTongDN_QH
        FROM pcb_hop_dong_duoc_cap a
        WHERE a.GRANTEDCONTRACT_ID LIKE  vPcb||'-%';

        SELECT SUM(DECODE(GRANTEDCONTRACT_ID,vPcb||'-TC' ,utilization))+ SUM(DECODE(GRANTEDCONTRACT_ID,vPcb||'-THE' ,b.residualAmount)) + vremainingInstalmentsAmount ,
            SUM(CASE WHEN nrOfDaysOfPaymentDelay>=10 AND GRANTEDCONTRACT_ID = vPcb||'-TC' THEN b.utilization END)
            +  SUM(CASE WHEN nrOfDaysOfPaymentDelay>=10 AND GRANTEDCONTRACT_ID = vPcb||'-THE' THEN b.residualAmount END)
            + vTongDN_QH
            INTO vremainingInstalmentsAmount, vTongDN_QH
        FROM pcb_hop_dong_duoc_cap a
        JOIN pcb_hop_dong_duoc_cap_dtl b ON a.PROFILES = b.PROFILES_ID
        WHERE a.GRANTEDCONTRACT_ID LIKE  vPcb||'-%'
        AND a.guarantedAmountFromGuarantor > 0  AND a.CONTRACTPHASE = 'LV'
        ;

        OPEN P_OUT FOR
        --bc pcb
        SELECT DISTINCT 'PCB' report,
            DECODE(a.idcard,NULL,a.document_number,DECODE(a.document_number,NULL,a.idcard,a.idcard||', '||a.document_number)) idcard, --CCCD/CMND/MST
            a.NAME, --ten
            a.main_address||DECODE(a.main_additional,NULL,NULL,'/ '||a.MAIN_ADDITIONAL) main_address, --dia chi
            b.ref_number , --sdt
            'ETC' ETC_NTC,--Phân khúc (ETC/NTC)
            vresponse_date - MIN(c.STARTINGDATE) OVER (PARTITION BY c.CONTRACTPHASE) STARTINGDATE, --Thời gian quan hệ tín dụng
            COUNT(DISTINCT CASE WHEN INSTR(c.encryptedficode,'B') > 0 THEN c.encryptedficode END) OVER (PARTITION BY c.CONTRACTPHASE)  encryptedficode_B, --Số NH đang có quan hệ
            COUNT(DISTINCT CASE WHEN INSTR(c.encryptedficode,'F') > 0 THEN c.encryptedficode END) OVER (PARTITION BY c.CONTRACTPHASE)  encryptedficode_F, --Số CTTC đang có quan hệ
            CASE WHEN TO_NUMBER(MAX(NVL(nrOfDaysOfPaymentDelay,0)) OVER (PARTITION BY c.CONTRACTPHASE)) BETWEEN 0 AND 9 THEN 1
                WHEN TO_NUMBER(MAX(nrOfDaysOfPaymentDelay) OVER (PARTITION BY c.CONTRACTPHASE)) BETWEEN 10 AND 90 THEN 2
                WHEN TO_NUMBER(MAX(nrOfDaysOfPaymentDelay) OVER (PARTITION BY c.CONTRACTPHASE)) BETWEEN 91 AND 180 THEN 3
                WHEN TO_NUMBER(MAX(nrOfDaysOfPaymentDelay) OVER (PARTITION BY c.CONTRACTPHASE)) BETWEEN 181 AND 360 THEN 4
                WHEN TO_NUMBER(MAX(nrOfDaysOfPaymentDelay) OVER (PARTITION BY c.CONTRACTPHASE)) > 360 THEN 5 END nrOfDaysOfPaymentDelay, --Nhóm nợ cao nhất hiện tại
            MAX(CASE WHEN c1.status >= 2  AND c1.referenceyear IS NOT NULL AND MONTHS_BETWEEN(vresponse_date, TO_DATE(TO_CHAR(SYSDATE,'DD')||'/'||c1.referencemonth||'/'||c1.referenceyear,'dd/mm/yyyy')) <= 12 THEN 1 ELSE 0 END
                ) OVER (PARTITION BY c.CONTRACTPHASE) profiles_Flag_1, --Flag nếu có nợ cần chú ý trong vòng 12 tháng
            MAX(CASE WHEN c1.status >= 3  AND c1.referenceyear IS NOT NULL AND MONTHS_BETWEEN(vresponse_date, TO_DATE(TO_CHAR(SYSDATE,'DD')||'/'||c1.referencemonth||'/'||c1.referenceyear,'dd/mm/yyyy')) <= 36 THEN 1 ELSE 0 END
                ) OVER (PARTITION BY c.CONTRACTPHASE) profiles_Flag_2, --Flag nếu có nợ xấu trong vòng 36 tháng
            MAX(CASE WHEN c1.status >= 3  AND c1.referenceyear IS NOT NULL AND MONTHS_BETWEEN(vresponse_date, TO_DATE(TO_CHAR(SYSDATE,'DD')||'/'||c1.referencemonth||'/'||c1.referenceyear,'dd/mm/yyyy')) <= 60 THEN 1 ELSE 0 END
                ) OVER (PARTITION BY c.CONTRACTPHASE) profiles_Flag_3, --Flag nếu có nợ xấu trong vòng 5 năm
            NULL DUNO_VAMC,--Flag nếu có nợ bán VAMC
            COUNT(DISTINCT CASE WHEN c.GRANTEDCONTRACT_ID LIKE '%-THE' THEN c.cbContractCode END ) OVER (PARTITION BY c.CONTRACTPHASE) cbContractCode, --Số lượng thẻ đang acitve
            NVL((d.AC_LIMITOFCREDIT + d.g_LIMITOFCREDIT),0) LIMITOFCREDIT, --Tổng hạn mức được cấp đối với thẻ đang active
            ROUND(vTongDN_PCB/vCREDITLIMIT,2) residualAmount, --Tỷ lệ sử dụng hạn mức thẻ
            DECODE(SUM( CASE WHEN c.GRANTEDCONTRACT_ID LIKE '%-THE' THEN c.residualAmount ELSE 0 END) OVER (PARTITION BY c.CONTRACTPHASE),0,0,
                SUM( CASE WHEN c.GRANTEDCONTRACT_ID LIKE '%-THE' THEN c.UnpaidDueInstalmentsAmount ELSE 0 END) OVER (PARTITION BY c.CONTRACTPHASE)
                /SUM( CASE WHEN c.GRANTEDCONTRACT_ID LIKE '%-THE' THEN c.residualAmount ELSE 0 END) OVER (PARTITION BY c.CONTRACTPHASE)) UnpaidDueInstalmentsAmount, --Tỷ lệ nợ quá hạn trên tổng dư nợ
            COUNT(DISTINCT (CASE WHEN c.guarantedAmountFromGuarantor = 0 THEN c.cbContractCode END)) OVER (PARTITION BY c.CONTRACTPHASE) count_cbContractCode_TINC, --Số lượng khoản vay tin chap
            (SUM(CASE WHEN c.GRANTEDCONTRACT_ID LIKE '%-TT' AND c.guarantedAmountFromGuarantor = 0 THEN c.remainingInstalmentsAmount ELSE 0 END ) OVER (PARTITION BY c.CONTRACTPHASE)
                + vUTILIZATION
                + SUM(CASE WHEN c.GRANTEDCONTRACT_ID LIKE '%-THE' AND c.guarantedAmountFromGuarantor = 0 THEN c1.residualAmount ELSE 0 END ) OVER (PARTITION BY c.CONTRACTPHASE)) RemainingInstalmentsAmount_TINC, --Tổng dư nợ tin chap
            NVL(ROUND((SUM(CASE WHEN c.GRANTEDCONTRACT_ID LIKE '%-TT' THEN c.remainingInstalmentsAmount ELSE 0 END ) OVER (PARTITION BY c.CONTRACTPHASE)
                + SUM(CASE WHEN c.GRANTEDCONTRACT_ID LIKE '%-TC' THEN c1.utilization ELSE 0 END ) OVER (PARTITION BY c.CONTRACTPHASE)
                + SUM(CASE WHEN c.GRANTEDCONTRACT_ID LIKE '%-THE' THEN c1.residualAmount ELSE 0 END ) OVER (PARTITION BY c.CONTRACTPHASE))
            /(SUM(CASE WHEN c.GRANTEDCONTRACT_ID LIKE '%-TT' AND c.nrOfDaysOfPaymentDelay >=10 AND c.guarantedAmountFromGuarantor = 0 THEN c.unpaidDueInstalmentsAmount END ) OVER (PARTITION BY c.CONTRACTPHASE)
                + SUM(CASE WHEN c.GRANTEDCONTRACT_ID LIKE '%-TC' AND c.nrOfDaysOfPaymentDelay >=10 AND c.guarantedAmountFromGuarantor = 0 THEN c1.utilization END ) OVER (PARTITION BY c.CONTRACTPHASE)
                + SUM(CASE WHEN c.GRANTEDCONTRACT_ID LIKE '%-THE' AND c.nrOfDaysOfPaymentDelay >=10 AND c.guarantedAmountFromGuarantor = 0 THEN c1.residualAmount END ) OVER (PARTITION BY c.CONTRACTPHASE)
            ),2),0) TL_NO_QUA_HAN_Tinc, --Tỷ lệ nợ quá hạn trên tổng dư nợ tin chap
            COUNT(DISTINCT (CASE WHEN c.guarantedAmountFromGuarantor > 0 THEN c.cbContractCode END)) OVER (PARTITION BY c.CONTRACTPHASE) count_cbContractCode_TheC, --Số lượng khoản vay the chap
            vremainingInstalmentsAmount  RemainingInstalmentsAmount_TheC, --Tổng dư nợ the chap
            vguarantedAmountFromGuarantor guarantedAmountFromGuarantor, --Tổng giá trị TSBĐ
            NVL(ROUND(vremainingInstalmentsAmount/vguarantedAmountFromGuarantor,2),0) LTV,--LTV
            NVL(ROUND((vTongDN_QH)/(vremainingInstalmentsAmount),2),0)  TL_NO_QUA_HAN, --Tỷ lệ nợ quá hạn trên tổng dư nợ
            vB + vB1 COUNT_encryptedFICode_B, --Số NH tra cứu thông tin tín dụng của KH (trong 1 năm gần nhất)
            vF + vF1 COUNT_encryptedFICode_F,--Số CTTC tra cứu thông tin tín dụng của KH (trong 1 năm gần nhất)
            CASE WHEN c.encryptedFICode = 'B01' AND e.contractphase IN ('RQ','RF') THEN 1 ELSE 0 END encryptedFICode_FLAG,--Flag nếu NCB đã từng tra cứu CIC của KH nhưng chưa cho vay (trong 1 năm gần nhất)
            NULL DIEM,--Điểm
            NULL HANG,--Hạng
            NULL PD,
            vresponse_date ngay_bc --Ngày CIC/PCB trả kết quả về iCredit
        FROM pcb_tt_chung a
            LEFT JOIN (SELECT mylistagg(ref_number) ref_number,CIS_NO,reference_id FROM pcb_tt_chung_reference WHERE TYPE = 'PN' GROUP BY CIS_NO,reference_id
                ) b ON b.reference_id = a.idcard AND b.CIS_NO = a.cis_no
            LEFT JOIN pcb_hop_dong_duoc_cap c ON instr(c.GRANTEDCONTRACT_ID ,a.cis_no||'-')>0 AND c.CONTRACTPHASE = 'LV'
            LEFT JOIN pcb_hop_dong_duoc_cap_dtl c1 ON c.profiles = c1.profiles_id
            LEFT JOIN pcb_the d ON a.cis_no = d.cis_no
            LEFT JOIN pcb_hop_dong_khong_duoc_cap e ON e.NOTGRANTEDCONTRACT_ID LIKE a.cis_no||'-%'
        WHERE a.cis_no = vPcb

        UNION ALL
        SELECT DISTINCT 'CIC' report,
            CASE WHEN vProduct_code IN ('R11A','S11A') THEN
                DECODE(a.cmnd_hc,NULL,a.giay_to_khac,DECODE(a.giay_to_khac,NULL,a.cmnd_hc,a.cmnd_hc||', '||a.giay_to_khac))
            ELSE DECODE(a.DKKD,NULL,a.mst,DECODE(a.mst,NULL,a.DKKD,a.DKKD||', '||a.mst)) END cmnd_hc, --CCCD/CMND/MST/ĐKKD
            a.ten_khach_hang, --Tên khách hàng
            a.dia_chi_tru_so_chinh, --Địa chỉ/ Địa chỉ trụ sở chính
            NULL sdt, --so dien thaoi
            vTT_TRALOI ETC, --thong tin ETC
            vngay_ky_hdtd  ngay_ky_hdtd,--Thời gian quan hệ tín dụng
            vsl_nh_tracuu count_ma_tctd,--Số NH đang có quan hệ
            vsl_cttc_tracuu CTTC,--Số CTTC đang có quan hệ
            vMax_nhomno nrOfDaysOfPaymentDelay_CIC, --Nhóm nợ cao nhất hiện tại
            MAX(CASE WHEN e.NHOM_DU_LIEU = 'NHOM2_12THANG' AND e.TONG_DU_NO > 0 THEN 1 ELSE 0 END) OVER (PARTITION BY e.response_id) NHOM2_12THANG, --Flag nếu có nợ cần chú ý trong vòng 12 tháng
            MAX(CASE WHEN e.NHOM_DU_LIEU = 'NOXAU_36THANG' AND MONTHS_BETWEEN(vTHOIGIANTL, TO_DATE(e.ngay_ps_no_xau_cuoi_cung,'yyyymmdd')) <= 36 THEN 1 ELSE 0 END) OVER (PARTITION BY e.response_id) NOXAU_36THANG, --Flag nếu có nợ cần chú ý trong vòng 36 tháng
            MAX(CASE WHEN e.NHOM_DU_LIEU = 'NOXAU_60THANG' AND MONTHS_BETWEEN(vTHOIGIANTL, TO_DATE(e.ngay_ps_no_xau_cuoi_cung,'yyyymmdd')) <= 60 THEN 1 ELSE 0 END) OVER (PARTITION BY e.response_id) NOXAU_60THANG, --Flag nếu có nợ cần chú ý trong vòng 60 tháng
            MAX(CASE WHEN c.loai_quan_he = 'DUNO_VAMC' AND c.NOGOC_CONLAI > 0 THEN 1 ELSE 0 END) OVER (PARTITION BY c.response_id) DUNO_VAMC, --Flag nếu có nợ bán VAMC
            MAX(CASE WHEN f.loai_thanh_toan = 'DUNO_THETD' THEN TO_NUMBER(f.SO_LUONG_THE) ELSE 0 END) OVER (PARTITION BY f.response_id) SO_LUONG_THE,--Số lượng thẻ đang acitve
            MAX(CASE WHEN f.loai_thanh_toan = 'DUNO_THETD' THEN TO_NUMBER(f.HAN_MUC) ELSE 0 END) OVER (PARTITION BY f.response_id) HAN_MUC,--Tổng hạn mức được cấp đối với thẻ đang active
            NVL(ROUND(SUM(CASE WHEN f.loai_thanh_toan = 'DUNO_THETD' THEN f.SO_TIEN_PHAI_TT END) OVER (PARTITION BY f.response_id)
            / SUM(CASE WHEN f.loai_thanh_toan = 'DUNO_THETD' THEN f.HAN_MUC END)  OVER (PARTITION BY f.response_id),2),0)  ti_le_sd, --Tỷ lệ sử dụng hạn mức thẻ
            NVL(ROUND(SUM(CASE WHEN f.loai_thanh_toan = 'DUNO_THETD' THEN f.SO_TIEN_CHAM_TT END) OVER (PARTITION BY f.response_id)
            / SUM(CASE WHEN f.loai_thanh_toan = 'DUNO_THETD' THEN f.SO_TIEN_PHAI_TT END)  OVER (PARTITION BY f.response_id),2),0)  ti_le_no_qh, --Tỷ lệ nợ quá hạn trên tổng dư nợ
            --SUM(CASE WHEN g.mo_ta = 'Có' THEN 0 ELSE 1 END) OVER (PARTITION BY g.response_id) sl_TSDB_tc, --Số lượng khoản vay tin chap
            COUNT(DISTINCT CASE WHEN a.MOTA_TSDB != 'Có' THEN b.so_hdtd END)OVER (PARTITION BY b.response_id) sl_TSDB_tc, --Số lượng khoản vay tin chap
            CASE WHEN a.MOTA_TSDB != 'Có' THEN NVL(vTongDN,0) END  tong_duno_tc,--Tổng dư nợ tin chap
            CASE WHEN a.MOTA_TSDB != 'Có' THEN NVL(vTyle,0) END  tyle_duno_tc,--Tỷ lệ nợ quá hạn trên tổng dư nợ tin chap
            COUNT(DISTINCT CASE WHEN a.MOTA_TSDB = 'Có' THEN b.so_hdtd END)OVER (PARTITION BY b.response_id) sl_TSDB_thec, --Số lượng khoản vay the chap
            CASE WHEN a.MOTA_TSDB = 'Có' THEN NVL(vTongDN,0) END  tong_duno_thec,--Tổng dư nợ the chap
            CASE WHEN a.MOTA_TSDB = 'Có' THEN vGIA_TRI_TSBD END tong_gt_tsdb_thec,--Tổng giá trị TSBĐ the chap
            CASE WHEN a.MOTA_TSDB = 'Có' THEN NVL(ROUND(vTongDN/vGIA_TRI_TSBD,2),0) END  LTV,--LTV
            CASE WHEN a.MOTA_TSDB = 'Có' THEN NVL(vTyle,0) END tyle_no_qua_han,--Tỷ lệ nợ quá hạn trên tổng dư nợ
            vsl_nh_tracuu,--Số NH tra cứu thông tin tín dụng của KH (trong 1 năm gần nhất)
            vsl_cttc_tracuu,--Số CTTC tra cứu thông tin tín dụng của KH (trong 1 năm gần nhất)
            MAX(CASE WHEN h.ma_tctd = '01352002' THEN 1 ELSE 0 END) OVER (PARTITION BY h.response_id) flag_ncb,--Flag nếu NCB đã từng tra cứu CIC của KH nhưng chưa cho vay (trong 1 năm gần nhất)
            vDIEM DIEM_CIC,--Điểm
            vHANG HANG_CIC,--Hạng
            vPD PD_CIC,
            vTHOIGIANTL ngay_bc_CIC --Ngày CIC/PCB trả kết quả về iCredit
        FROM tbl_cis_thong_tin_chung a
            LEFT JOIN TBL_CIS_TT_TONG_HOP_KHAC_HDTD b ON a.response_id = b.response_id
            LEFT JOIN TBL_CIS_QUAN_HE_TIN_DUNG c ON a.response_id = c.response_id
            LEFT JOIN TBL_CIS_DU_NO_HIEN_THOI d ON a.response_id = d.response_id
            LEFT JOIN TBL_CIS_LS_QUAN_HE_TIN_DUNG e ON a.response_id = e.response_id
            LEFT JOIN TBL_CIS_TT_THANH_TOAN_THE f ON a.response_id = f.response_id
            LEFT JOIN TBL_CIS_TSDB g ON a.response_id = g.response_id
            LEFT JOIN TBL_CIS_LICH_SU_TRA_CUU h ON a.response_id = h.response_id
        WHERE a.response_id = vCic;

    END;

Function GET_DOCUMENT_ELEMENT(p_cis_no varchar2) RETURN  varchar2
IS
response		CLOB;
count_number 	NUMBER;
index_number	NUMBER;
doc_typr		varchar2(1000);
doc_number		varchar2(1000);
BEGIN
		count_number := 0;
		index_number :=	0;
		SELECT cr.response_data INTO response FROM CIS_RESPONSE cr WHERE cr.cis_no = p_cis_no;

	    SELECT  count(1) INTO count_number
                FROM
                (SELECT JS.*
                FROM JSON_TABLE(response, '$.rIReqOutput.subject.matched.person.document[*]'
                    COLUMNS
                        (
                        DOCUMENT_TYPE  VARCHAR2(500) PATH '$.type',
                        DOCUMENT_NUMBER  VARCHAR2(500) PATH '$.number'
                        )) AS js
                ) a ;
          IF count_number > 1 THEN
	          FOR item IN (SELECT  *
				                FROM
				                (SELECT JS.*
				                FROM JSON_TABLE(response, '$.rIReqOutput.subject.matched.person.document[*]'
				                    COLUMNS
				                        (
				                        DOCUMENT_TYPE  VARCHAR2(500) PATH '$.type',
				                        DOCUMENT_NUMBER  VARCHAR2(500) PATH '$.number'
				                        )) AS js
				                ) a) LOOP

	           IF (index_number = 0)THEN
	           	doc_typr		:= item.DOCUMENT_TYPE;
	           	doc_number 		:= item.DOCUMENT_NUMBER;
	           ELSE
	           	doc_typr		:= doc_typr 	|| ',' ||	item.DOCUMENT_TYPE;
	           	doc_number 		:= doc_number 	|| ',' ||	item.DOCUMENT_NUMBER;
	           END IF;
	           index_number := index_number +1;
			END LOOP;
		RETURN doc_typr || '@'||doc_number;
		ELSE
		RETURN NULL;
		END IF;

END;
END ;