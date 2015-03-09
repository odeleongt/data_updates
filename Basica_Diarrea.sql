USE [ViCo]
GO

/****** Object:  View [Clinicos].[Basica_Diarrea]    Script Date: 03/09/2015 17:45:59 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO







/*
	Creada por: Gerardo López
	Fecha: algún día de 2007 o 2008

	Esta vista provee información básica para iniciar análisis en los casos de
	diarrea de ViCo. Se unen datos de Hospital, Centro y Puesto.

	[2011-10-21] Fredy Muñoz:
	* Actualicé algunos comentarios que hacían referencia a Hospital en los
	  bloques de Centro y Puesto. Probablemente se quedaron por copy/paste.
	* Moví el bloque de Hospital al principio para tener un orden más lógico.
	* Hice JOIN con la tabla Control.Sitios para obtener la información de los
	  sitios en lugar de producirlo en el query.

	[2011-11-10] Fredy Muñoz:
	* Agregué columna hxC_Vomitos que es el nuevo nombre de
	  sintomasEnfermDiarreaVomitos pero aun no la reemplacé.

	[2012-03-08] Fredy Muñoz:
	* Agregué columnas: parentescoGradoEscolarCompleto, familiaIngresosMensuales

	[2012-05-22] Fredy Muñoz:
	* Agregué columna: centroRehidratacionTipo que solamente está disponible en
	  Centro.

	[2012-10-12] Fredy Muñoz:
	* Cambié el nombre de la variable [catchment] a [HUSarea]

	[2012-12-10] Fredy Muñoz:
	* Resumí el código para calcular [HUSarea]. Esta forma resulta más fácil de
	  leer.
	* Agregué variable [medUltimas72HorasAntiB].
	
	[2013-04-19] Marvin Xuya
	* Agregue variables 
		[EPEC]
		[ETEC]
		[STEC]
	* Renombré la variable [ecoli] a [EntamoebaColi]
	
	[2014-02-21] Fredy Muñoz
	* Agregué las siguientes variables:
		[casaRefrigeradora]
		[casaComputadora]
		[casaRadio]
		[casaLavadora]
		[casaSecadora]
		[casaTelefono]
		[casaMicroondas]
		[casaCarroCamion]
		
	[2014-04-03] Karin Ceballos
	* Agregue las variables 
	   [ASTROVIRUS]
      ,[SAPOVIRUS]
      ,[CT_ASTROVIRUS]
      ,[CT_SAPOVIRUS]
      
	[2014-05-30]       Karin Ceballos
	Agregue las variables a solicitud de CJarquin
	casaCuantosDormitorios
casaCuantasPersonasViven
casaMaterialTecho
combustibleLenia
combustibleResiduosCosecha
combustibleCarbon
combustibleGas
combustibleElectricidad
combustibleOtro

[2014-08-05] Karin Ceballos
Agregue Variables a Solicitud de Claudia Jarquin
Patientegradoescolar
casaEnergiaElectrica


	
*/

CREATE VIEW [Clinicos].[Basica_Diarrea]
AS

-- Hospital
SELECT
	Sujeto.[SubjectID]


	-- ID & elegibility
	-----------------------------------------------
	,pacienteInscritoViCo
	,Sujeto.SASubjectID

	,elegibleDiarrea
	,elegibleRespira
	,elegibleNeuro
	,elegibleFebril
	-----------------------------------------------


	-- Dates
	-----------------------------------------------
	,fechaHoraAdmision
	,epiWeekAdmision
	,epiYearAdmision
	-----------------------------------------------


	-- Consent
	-----------------------------------------------
	,consentimientoVerbal
	,consentimientoEscrito
	,asentimientoEscrito
	-----------------------------------------------


	-- Site location
	-----------------------------------------------
	,SubjectSiteID
	,Sitios.TipoSitio AS SiteType
	,Sitios.DeptoShortName AS SiteDepartamento
	-----------------------------------------------


	-- Patient Location
	-----------------------------------------------
	,Sujeto.departamento
	,Sujeto.municipio
	,comunidad
	,HUSarea =
		CASE
			WHEN
				(
					Sujeto.departamento = 6
					AND SubjectSiteID IN (1, 2, 3, 4, 5, 6, 7)
					AND Sujeto.municipio IN (601, 602, 603, 604, 605, 606, 607, 610, 612, 613, 614)
				)
				OR
				(
					Sujeto.departamento = 9
					AND SubjectSiteID IN (9, 12, 13, 14, 15)
					AND Sujeto.municipio IN (901, 902, 903, 909, 910, 911, 913, 914, 916, 923)
				)
				OR
				(
					Sujeto.departamento = 1
					AND SubjectSiteID = 11
				)
			THEN 1
			ELSE 2
		END

	,NombreDepto.Text as NombreDepartamento
	,NombreMuni.Text as NombreMunicipio
	-----------------------------------------------


	-- Demographic
	-----------------------------------------------
	,sexo
	,edadAnios
	,edadMeses
	,edadDias
	,fechaDeNacimiento=convert (date,[fechaDeNacimiento],113)
	,Sujeto.pacienteGrupoEtnico
	-----------------------------------------------


	-- Death information
	-----------------------------------------------
	,muerteViCo =
		CASE
			WHEN egresoTipo = 4 OR seguimientoPacienteCondicion = 3 THEN 1
			ELSE 2
		END

	,muerteViCoFecha =
		CASE
			WHEN egresoTipo = 4 THEN egresoMuerteFecha
			WHEN seguimientoPacienteCondicion = 3 THEN seguimientoPacienteMuerteFecha
			ELSE NULL
		END

	,muerteSospechoso = -- H1, H2CV, H2CE
		CASE
			WHEN h1TipoEgreso = 4 OR ConsentimientoVerbalNoRazonMurio = 1 OR ConsentimientoEscritoMurio = 1 THEN 1
			ELSE 2
		END

	,muerteSospechosoFecha =
		CASE
			WHEN h1TipoEgreso = 4 THEN h1FechaEgreso
			WHEN ConsentimientoVerbalNoRazonMurio = 1 OR ConsentimientoEscritoMurio = 1 THEN Sujeto.PDAInsertDate
			ELSE NULL
		END

	,muerteHospital =
		-- 1 = En Hospital (tamizaje, duranteEntrevista, antes de egresoCondicion H7)
		-- 2 = AfueraHospital (seguimiento)
		CASE
			WHEN (h1TipoEgreso = 4 OR ConsentimientoVerbalNoRazonMurio = 1 OR ConsentimientoEscritoMurio = 1 OR egresoTipo = 4) THEN 1
			WHEN seguimientoPacienteCondicion = 3 THEN 2
			ELSE NULL
		END

	,muerteCualPaso =
		-- 1 = Tamizaje/Consentimiento
		-- 2 = Durante Entrevista (Inscrito, but NOT everything IS done HCP11 filled out probably)
		-- 3 = Antes de egreso (H7)
		-- 4 = Seguimiento (HCP9)
		CASE	
			WHEN h1TipoEgreso = 4 OR ConsentimientoVerbalNoRazonMurio = 1 OR ConsentimientoEscritoMurio = 1 THEN 1
			WHEN terminoManeraCorrectaNoRazon = 3 THEN 2
			WHEN egresoTipo = 4 THEN 3
			WHEN seguimientoPacienteCondicion = 3 THEN 4
			ELSE NULL
		END

	,moribundoViCo = --H7
		CASE
			WHEN egresoCondicion = 4 AND (seguimientoPacienteCondicion IS NULL OR seguimientoPacienteCondicion <> 3) THEN 1 -- (moribundo) but NO seguimientoPacienteCondicion = 3  seguimientoPacienteMuerteFecha OR they are still alive!
			ELSE NULL
		END

	,moribundoViCoFecha = --H7
		CASE
			WHEN egresoCondicion = 4 AND (seguimientoPacienteCondicion IS NULL OR seguimientoPacienteCondicion <> 3) THEN egresoMuerteFecha -- (moribundo) but NO seguimientoPacienteCondicion = 3  seguimientoPacienteMuerteFecha OR they are still alive!
			ELSE NULL
		END

	,moribundoSospechoso = --H1
		CASE
			WHEN condicionEgreso = 4 THEN 1
			ELSE NULL
		END

	,moribundoSospechosoFecha = --H1
		CASE
			WHEN condicionEgreso = 4 THEN Sujeto.PDAInsertDate
			ELSE NULL
		END
	-----------------------------------------------


	-----------------------------------------------
	,presentaIndicacionDiarrea
	,indicacionDiarrea
	,indicacionDiarrea_otra
	,temperaturaPrimeras24Horas
	,ingresoPlanBPlanC
	,gradoDeshidratacionRegistrado
	,gradoDeshidratacion
	,conteoGlobulosBlancos
	,diferencialAnormal
	,sintomasFiebre
	,sintomasFiebreDias
	,ninioVomitaTodo
	,ninioBeberMamar
	,ninioTuvoConvulsiones
	,ninioTieneLetargiaObs AS ninioTieneLetargia
	,diarreaUltimos7Dias
	,diarreaComenzoHaceDias
	,diarreaMaximoAsientos1Dia
	,diarreaOtroEpisodioSemanaAnterior
	,muestraHecesColecta
	,MuestraHecesNoRazon
	,MuestraHecesNoRazonOtra_esp
	,muestraHecesHisopoSecoNoRazon
	,muestraHecesHisopoSecoNoRazonOtra_esp
	,muestraHecesHisopoSecoFechaHora
	,muestraHecesHisopoCaryBlairColecta
	,muestraHecesHisopoCaryBlairNoRazon
	,muestraHecesHisopoCaryBlairNoRazonOtra_esp
	,muestraHecesHisopoCaryBlairFechaHora
	,muestraHecesHisopoCaryBlairTipo
	,muestraHecesEnteraColecta
	,muestraHecesEnteraNoRazon
	,muestraHecesEnteraNoRazonOtra_Esp
	,muestraHecesEnteraFechaHora
	,muestraHecesEnteraLiquida
	,muestraHecesEnteraCubreFondo
	,hxD_diarreaActual
	,hxD_diarreaActualHaceDias
	,hxD_ConSangre
	,hxD_ConMoco
	,H3L.hxC_Vomitos
	,sintomasEnfermDiarreaVomitos
	,sintomasEnfermDiarreaVomitosVeces
	,sintomasEnfermDiarreaVomitos8Dias
	,sintomasEnfermDiarreaVomitosActual
	,hxD_calambresDolorAbdominal
	,hxD_condicionIntestinal
	,hxD_condicionIntestinal_esp
	,hxD_bebeConSed
	,hxD_irritableIncomodoIntranquilo
	,NULL AS centroRehidratacionTipo
	,otroTratamiento1erRecibioMedicamento
	,otroTratamiento1erAntibioticos
	,otroTratamiento1erSuerosSalesHidracionCasero
	,otroTratamiento2doRecibioMedicamento
	,otroTratamiento2doAntibioticos
	,otroTratamiento2doSuerosSalesHidracionCasero
	,otroTratamiento3erRecibioMedicamento
	,otroTratamiento3erAntibioticos
	,otroTratamiento3erSuerosSalesHidracionCasero
	,medUltimas72HorasAntiB
	,tomadoSuerosSalesUltimas72hora
	,claseSRORecibido
	,enfermedadesCronicasVIHSIDA
	,enfermedadesCronicasOtras
	,enfermedadesCronicasInfoAdicional
	,embarazada
	,embarazadaMeses
	,tieneFichaVacunacion
	,vacunaRotavirusRecibido
	,vacunaRotavirusDosis
	,Sujeto.casaNiniosGuareriaInfantil
	,Sujeto.pacientePachaPecho
	,Sujeto.parentescoGradoEscolarCompleto
	,Sujeto.patienteGradoEscolarCompleto
	
	,Sujeto.familiaIngresosMensuales
	,Sujeto.fuentesAguaChorroDentroCasaRedPublica
	,Sujeto.fuentesAguaChorroPublico
	,Sujeto.fuentesAguaChorroPatioCompartidoOtraFuente
	,Sujeto.fuentesAguaLavaderosPublicos
	,Sujeto.fuentesAguaPozoPropio
	,Sujeto.fuentesAguaPozoPublico
	,Sujeto.fuentesAguaCompranAguaEmbotellada
	,Sujeto.fuentesAguaDeCamionCisterna
	,Sujeto.fuentesAguaLluvia
	,Sujeto.fuentesAguaRioLago
	,Sujeto.casaAlmacenanAgua
	,Sujeto.aguaLimpiarTratar
	,Sujeto.aguaLimpiarTratarHierven
	,Sujeto.aguaLimpiarTratarQuimicos
	,Sujeto.aguaLimpiarTratarFiltran
	,Sujeto.aguaLimpiarTratarSodis
	,Sujeto.aguaLimpiarTratarOtro
	,Sujeto.aguaLimpiarTratarOtro_esp
	,Sujeto.casaMaterialPiso
	
	, sujeto.casaEnergiaElectrica
	,Sujeto.casaRefrigeradora
	,Sujeto.casaComputadora
	,Sujeto.casaRadio
	,Sujeto.casaLavadora
	,Sujeto.casaSecadora
	,Sujeto.casaTelefono
	,Sujeto.casaMicroondas
	,Sujeto.casaCarroCamion
	,Sujeto.factoresRiesgoInfoAdicional
	, h3f.combustibleLenia
	, h3f.combustibleResiduosCosecha
	, h3f.combustibleCarbon
	, h3f.combustibleGas
	, h3f.combustibleElectricidad
	, h3f.combustibleOtro
	,diarreaExamenFisicoEnfermeraOjos
	,diarreaExamenFisicoEnfermeraMucosaOral
	,diarreaExamenFisicoEnfermeraRellenoCapillar
	,diarreaExamenFisicoEnfermeraPellizcoPiel
	,diarreaExamenFisicoEnfermeraMolleraHundida
	,diarreaExamenFisicoEnfermeraEstadoMental
	,pacienteTallaMedida
	,pacienteTallaCM1
	,pacienteTallaCM2
	,pacienteTallaCM3
	,pacientePesoMedida
	,pacientePesoLibras1
	,pacientePesoLibras2
	,pacientePesoLibras3
	,egresoMuerteFecha

	,egresoTipo
	,egresoCondicion

	,temperaturaPrimeras24HorasAlta
	,egresoDiagnostico1
	,egresoDiagnostico1_esp
	,egresoDiagnostico2
	,egresoDiagnostico2_esp

	--,H7QRecibioAcyclovir AS RecibioAcyclovir
	--,H7Q0210 AS RecibioAmantadina
	,H7Q0211 AS RecibioAmikacina
	,H7Q0213 AS RecibioAmoxAcidoClavulanico
	,H7Q0212 AS RecibioAmoxicilina
	,H7Q0214 AS RecibioAmpicilina
	,H7Q0215 AS RecibioAmpicilinaSulbactam
	,H7Q0216 AS RecibioAzitromicina
	,H7QRecibioCefadroxil AS RecibioCefadroxil
	,H7Q0219 AS RecibioCefalotina
	,H7QRecibioCefepime AS RecibioCefepime
	,H7Q0217 AS RecibioCefotaxima
	,H7Q0218 AS RecibioCeftriaxone
	,H7Q0220 AS RecibioCefuroxima
	,H7Q0221 AS RecibioCiprofloxacina
	,NULL AS RecibioClaritromicina /*INCLUDE*/
	,H7Q0222 AS RecibioClindamicina
	,H7Q0223 AS RecibioCloranfenicol
	--,H7Q0224 AS RecibioDexametazona
	,H7Q0225 AS RecibioDicloxicina
	,H7Q0226 AS RecibioDoxicilina
	,H7QRecibioEritromicina AS RecibioEritromicina
	,H7Q0227 AS RecibioGentamicina
	--,H7Q0228 AS RecibioHidrocortizonaSuccin
	,H7QRecibioImipenem AS RecibioImipenem
	--,RecibioIsoniacida
	--,RecibioLevofloxacina
	--,H7Q0229 AS RecibioMeropenem
	--,H7Q0230 AS RecibioMetilprednisolona
	,H7Q0231 AS RecibioMetronidazol
	,H7Q0234 AS RecibioOfloxacina
	--,H7Q0235 AS RecibioOseltamivir
	,H7Q0298 AS RecibioOtroAntibiotico
	,H7Q0299 AS RecibioOtroAntibEspecifique
	,H7QRecibioOxacilina AS RecibioOxacilina
	,H7Q0232 AS RecibioPenicilina
	--,H7QRecibioPerfloxacinia AS RecibioPerfloxacinia
	,NULL AS RecibioPirazinamida /*INCLUDE*/
	--,H7Q0233 AS RecibioPrednisona
	,NULL AS RecibioRifampicina /*INCLUDE*/
	,H7Q0236 AS RecibioTrimetroprimSulfame
	,H7Q0237 AS RecibioVancomicina

	--,h7.sueroSalesDurAdmision
	--,h7.liquidosIntravenososDurAdmision
	,seguimientoPacienteCondicion
	-----------------------------------------------


	-- PDA Insert Info
	-----------------------------------------------
	,Sujeto.PDAInsertDate
	,Sujeto.PDAInsertVersion
	-----------------------------------------------


	-- Laboratory Results
	-----------------------------------------------
	,LAB.recepcionMuestraOriginal
	,LAB.recepcionMuestraHisopo
	,LAB.recepcionMuestraPVA
	,LAB.recepcionMuestraFormalina
	,LAB.floranormal
	,LAB.salmonella
	,LAB.salmonellaSp
	,LAB.shigella
	,LAB.shigellaSp
	,LAB.campylobacter
	,LAB.campylobacterSp
	,LAB.otro
	,LAB.pruebaRotavirusHizo
	,LAB.rotavirus
	,LAB.pruebaExamenFrescoHizo
	,LAB.pruebaExamenTricromicoHizo
	,LAB.pruebaExamenIFHizo
	,LAB.ascaris
	,LAB.trichiuris
	,LAB.nana
	,LAB.diminuta
	,LAB.uncinaria
	,LAB.enterobius
	,EntamoebaColi = LAB.ecoli
	,LAB.giardia
	,LAB.crypto
	,LAB.ioda
	,LAB.endolimax
	,LAB.chilo
	,LAB.blasto
	,LAB.NSOP
	,LAB.observaciones
	,LAB.pruebaCultivoHizo
	,LAB.pruebaExamenFrescoSpA
	,LAB.pruebaExamenFrescoSpB
	,LAB.pruebaExamenFrescoSpC
	,LAB.pruebaExamenTricromicoSpA
	,LAB.pruebaExamenTricromicoSpB
	,LAB.pruebaExamenTricromicoSpC
	,LAB.pruebaExamenIFSpA
	,LAB.pruebaExamenIFSpB
	--,LAB.PCREColi
	--,LAB.pruebaPCREColiHizo
	,LAB.pruebaRotavirusTipificacionHizo
	,LAB.rotavirusTipificacion
	,LAB.recepcionMuestraCongeladas
	,LAB.strong
	,LAB.recepcionMuestraNorovirus
	,LAB.Observaciones_UVG
	,LAB.taenia
	-----------------------------------------------


	-- Norovirus
	-----------------------------------------------
	,Norovirus.labNumeroNorovirus
	,Norovirus.fechaExtraccion
	,Norovirus.RTqPCR_RNP
	,Norovirus.RTqPCR_NV1
	,Norovirus.RTqPCR_NV2
	,Norovirus.RTqPCR_RNP_CT
	,Norovirus.RTqPCR_NV1_CT
	,Norovirus.RTqPCR_NV2_CT
	,Norovirus.observaciones AS ObservacionesNorovirus
	-----------------------------------------------


	-- Sensiblidad Antibiotica
	-----------------------------------------------
	,Sensibilidad.pruebaTrimetoprinSulfaSensibilidad
	,Sensibilidad.pruebaTetraciclinaSensibilidad
	,Sensibilidad.pruebaKanamicinaSensibilidad
	,Sensibilidad.pruebaGentamicinaSensibilidad
	,Sensibilidad.pruebaEstreptomicinaSensibilidad
	,Sensibilidad.pruebaCloranfenicolSensibilidad
	,Sensibilidad.pruebaCiprofloxacinaSensiblidad
	,Sensibilidad.pruebaCeftriaxoneSensibilidad
	,Sensibilidad.pruebaAmpicilinaSensibilidad
	,Sensibilidad.pruebaAmoxicilinaSensibilidad
	,Sensibilidad.pruebaAcNalidixicoSensibilidad
	,Sensibilidad.observaciones as ObservacionesSensibilidad
	-----------------------------------------------

	-- E.coli EscheridiaColi
	-----------------------------------------------
	,EscheridiaColi.EPEC
	,EscheridiaColi.ETEC
	,EscheridiaColi.STEC
	-----------------------------------------------
	--ASTRO Y SAPO virus 
	  ,[ASTROVIRUS]
      ,[SAPOVIRUS]
      ,[CT_ASTROVIRUS]
      ,[CT_SAPOVIRUS]
	

FROM Clinicos.Todo_Hospital_vw Sujeto 
	LEFT JOIN Control.Sitios ON Sujeto.SubjectSiteID = Sitios.SiteID
	LEFT JOIN LegalValue.LV_DEPARTAMENTO NombreDepto ON Sujeto.departamento = NombreDepto.Value
	LEFT JOIN LegalValue.LV_MUNICIPIO NombreMuni ON Sujeto.municipio = NombreMuni.Value
	LEFT JOIN Lab.DiarreaResultados LAB ON Sujeto.SASubjectID = Lab.ID_Paciente
	LEFT JOIN Lab.NorovirusResultados Norovirus ON Sujeto.SASubjectID = Norovirus.ID_Paciente
	LEFT JOIN Lab.DiarreaResultadosAntibiotiocs Sensibilidad ON Sujeto.SASubjectID = Sensibilidad.ID_Paciente

	-- FM[2011-11-10]: Temporal mientras corrigo Todo_Hospital
	LEFT JOIN Clinicos.H3L ON H3L.SubjectID = Sujeto.SubjectID AND H3L.forDeletion = 0
	LEFT JOIN Clinicos.H3F  H3F ON H3F.SubjectID = Sujeto.SubjectID AND H3F.forDeletion = 0
	LEFT JOIN Lab.EColi_Resultados EscheridiaColi ON EscheridiaColi.SubjectID = Sujeto.SubjectID 
	left JOIN sp.Sindrome_Diarreico sd  on sujeto.SASubjectID collate database_default= sd.SaSubjectID collate database_default
	
WHERE Sujeto.forDeletion = 0



UNION ALL



-- Centro de Salud
SELECT
	Sujeto.[SubjectID]


	-- ID & elegibility
	-----------------------------------------------
	,pacienteInscritoViCo
	,Sujeto.SASubjectID

	,elegibleDiarrea
	,elegibleRespira
	,elegibleNeuro
	,elegibleFebril
	-----------------------------------------------


	-- Dates
	-----------------------------------------------
	,fechaHoraAdmision
	,epiWeekAdmision
	,epiYearAdmision
	-----------------------------------------------


	-- Consent
	-----------------------------------------------
	,consentimientoVerbal
	,consentimientoEscrito
	,asentimientoEscrito
	-----------------------------------------------


	-- Site location
	-----------------------------------------------
	,SubjectSiteID
	,Sitios.TipoSitio AS SiteType
	,Sitios.DeptoShortName AS SiteDepartamento
	-----------------------------------------------


	-- Patient Location
	-----------------------------------------------
	,Sujeto.departamento
	,Sujeto.municipio
	,comunidad
	,HUSarea =
		CASE
			WHEN
				(
					Sujeto.departamento = 6
					AND SubjectSiteID IN (1, 2, 3, 4, 5, 6, 7)
					AND Sujeto.municipio IN (601, 602, 603, 604, 605, 606, 607, 610, 612, 613, 614)
				)
				OR
				(
					Sujeto.departamento = 9
					AND SubjectSiteID IN (9, 12, 13, 14, 15)
					AND Sujeto.municipio IN (901, 902, 903, 909, 910, 911, 913, 914, 916, 923)
				)
				OR
				(
					Sujeto.departamento = 1
					AND SubjectSiteID = 11
				)
			THEN 1
			ELSE 2
		END

	,NombreDepto.Text as NombreDepartamento
	,NombreMuni.Text as NombreMunicipio
	-----------------------------------------------


	-- Demographic
	-----------------------------------------------
	,sexo
	,edadAnios
	,edadMeses
	,edadDias
	,fechaDeNacimiento=convert (date,[fechaDeNacimiento],113)
	,Sujeto.pacienteGrupoEtnico
	-----------------------------------------------


	-- Death information
	-----------------------------------------------
	,muerteViCo =
		CASE
			WHEN egresoTipo  = 4 OR seguimientoPacienteCondicion = 3 THEN 1
			ELSE 2
		END

	,muerteViCoFecha = 
		CASE
			WHEN egresoTipo = 4 THEN Sujeto.PDAInsertDate
			WHEN seguimientoPacienteCondicion = 3 THEN seguimientoPacienteMuerteFecha
			ELSE NULL
		END

	,muerteSospechoso = --C0, C1CV, C1CE
		CASE
			WHEN ConsentimientoVerbalNoRazonMurio = 1 OR ConsentimientoEscritoMurio = 1 THEN 1
			ELSE 2
		END

	,muerteSospechosoFecha =
		CASE
			WHEN ConsentimientoVerbalNoRazonMurio = 1 OR ConsentimientoEscritoMurio = 1 THEN Sujeto.PDAInsertDate
			ELSE NULL
		END

	,NULL AS muerteHospital

	,muerteCualPaso =
		-- 1 = Tamizaje/Consentimiento
		-- 2 = Durante Entrevista (Inscrito, but NOT everything IS done HCP11 filled out probably)
		-- 3 = Antes de egreso (C7)
		-- 4 = Seguimiento (HCP9)
		CASE	
			WHEN ConsentimientoVerbalNoRazonMurio = 1 OR ConsentimientoEscritoMurio = 1 THEN 1
			WHEN terminoManeraCorrectaNoRazon = 3 THEN 2
			WHEN egresoTipo = 4 THEN 3
			WHEN seguimientoPacienteCondicion = 3THEN 4
			ELSE NULL
		END

	,NULL AS moribundoViCo --C7?
	,NULL AS moribundoViCoFecha --C7?
	,NULL AS moribundoSospechoso
	,NULL AS moribundoSospechosoFecha
	-----------------------------------------------


	-----------------------------------------------
	,presentaIndicacionDiarrea
	,indicacionDiarrea
	,indicacionDiarrea_otra
	,temperaturaPrimeras24Horas
	,NULL AS ingresoPlanBPlanC
	,NULL AS gradoDeshidratacionRegistrado
	,NULL AS gradoDeshidratacion
	,NULL AS conteoGlobulosBlancos
	,NULL AS diferencialAnormal
	,sintomasFiebre
	,sintomasFiebreDias
	,ninioVomitaTodo
	,ninioBeberMamar
	,ninioTuvoConvulsiones
	,ninioTieneLetargia
	,diarreaUltimos7Dias
	,diarreaComenzoHaceDias
	,diarreaMaximoAsientos1Dia
	,diarreaOtroEpisodioSemanaAnterior
	,muestraHecesColecta
	,MuestraHecesNoRazon
	,MuestraHecesNoRazonOtra_esp
	,muestraHecesHisopoSecoNoRazon
	,muestraHecesHisopoSecoNoRazonOtra_esp
	,muestraHecesHisopoSecoFechaHora
	,muestraHecesHisopoCaryBlairColecta
	,muestraHecesHisopoCaryBlairNoRazon
	,muestraHecesHisopoCaryBlairNoRazonOtra_esp
	,muestraHecesHisopoCaryBlairFechaHora
	,muestraHecesHisopoCaryBlairTipo
	,muestraHecesEnteraColecta
	,muestraHecesEnteraNoRazon
	,muestraHecesEnteraNoRazonOtra_Esp
	,muestraHecesEnteraFechaHora
	,muestraHecesEnteraLiquida
	,muestraHecesEnteraCubreFondo
	,hxD_diarreaActual
	,hxD_diarreaActualHaceDias
	,hxD_ConSangre
	,hxD_ConMoco
	,C2L.hxC_Vomitos
	,sintomasEnfermDiarreaVomitos
	,sintomasEnfermDiarreaVomitosVeces
	,sintomasEnfermDiarreaVomitos8Dias
	,sintomasEnfermDiarreaVomitosActual
	,hxD_calambresDolorAbdominal
	,hxD_condicionIntestinal
	,hxD_condicionIntestinal_esp
	,hxD_bebeConSed
	,hxD_irritableIncomodoIntranquilo
	,centroRehidratacionTipo
	,otroTratamiento1erRecibioMedicamento
	,otroTratamiento1erAntibioticos
	,otroTratamiento1erSuerosSalesHidracionCasero
	,otroTratamiento2doRecibioMedicamento
	,otroTratamiento2doAntibioticos
	,otroTratamiento2doSuerosSalesHidracionCasero
	,NULL AS otroTratamiento3erRecibioMedicamento
	,NULL AS otroTratamiento3erAntibioticos
	,NULL AS otroTratamiento3erSuerosSalesHidracionCasero
	,medUltimas72HorasAntiB
	,tomadoSuerosSalesUltimas72hora
	,claseSRORecibido
	,enfermedadesCronicasVIHSIDA
	,enfermedadesCronicasOtras
	,enfermedadesCronicasInfoAdicional
	,embarazada
	,embarazadaMeses
	,tieneFichaVacunacion
	,vacunaRotavirusRecibido
	,vacunaRotavirusDosis
	,Sujeto.casaNiniosGuareriaInfantil
	,Sujeto.pacientePachaPecho
	,Sujeto.parentescoGradoEscolarCompleto
	,Sujeto.patienteGradoEscolarCompleto
	,Sujeto.familiaIngresosMensuales
	,Sujeto.fuentesAguaChorroDentroCasaRedPublica
	,Sujeto.fuentesAguaChorroPublico
	,Sujeto.fuentesAguaChorroPatioCompartidoOtraFuente
	,Sujeto.fuentesAguaLavaderosPublicos
	,Sujeto.fuentesAguaPozoPropio
	,Sujeto.fuentesAguaPozoPublico
	,Sujeto.fuentesAguaCompranAguaEmbotellada
	,Sujeto.fuentesAguaDeCamionCisterna
	,Sujeto.fuentesAguaLluvia
	,Sujeto.fuentesAguaRioLago
	,Sujeto.casaAlmacenanAgua
	,Sujeto.aguaLimpiarTratar
	,Sujeto.aguaLimpiarTratarHierven
	,Sujeto.aguaLimpiarTratarQuimicos
	,Sujeto.aguaLimpiarTratarFiltran
	,Sujeto.aguaLimpiarTratarSodis
	,Sujeto.aguaLimpiarTratarOtro
	,Sujeto.aguaLimpiarTratarOtro_esp
	,Sujeto.casaMaterialPiso
	, sujeto.casaEnergiaElectrica
	,Sujeto.casaRefrigeradora
	,Sujeto.casaComputadora
	,Sujeto.casaRadio
	,Sujeto.casaLavadora
	,Sujeto.casaSecadora
	,Sujeto.casaTelefono
	,Sujeto.casaMicroondas
	,Sujeto.casaCarroCamion
	,Sujeto.factoresRiesgoInfoAdicional
	, C2F.combustibleLenia
	, C2F.combustibleResiduosCosecha
	, C2F.combustibleCarbon
	, C2F.combustibleGas
	, C2F.combustibleElectricidad
	, C2F.combustibleOtro
	
	
	
	
	
	,diarreaExamenFisicoEnfermeraOjos
	,diarreaExamenFisicoEnfermeraMucosaOral
	,diarreaExamenFisicoEnfermeraRellenoCapillar
	,diarreaExamenFisicoEnfermeraPellizcoPiel
	,diarreaExamenFisicoEnfermeraMolleraHundida
	,diarreaExamenFisicoEnfermeraEstadoMental
	,pacienteTallaMedida
	,pacienteTallaCM1
	,pacienteTallaCM2
	,pacienteTallaCM3
	,pacientePesoMedida
	,pacientePesoLibras1
	,pacientePesoLibras2
	,pacientePesoLibras3
	,Sujeto.PDAInsertDate AS egresoMuerteFecha

	,egresoTipo
	,NULL AS egresoCondicion

	,temperaturaPrimeras24Horas AS temperaturaPrimeras24HorasAlta
	,egresoDiagnostico1
	,egresoDiagnostico1_esp
	,egresoDiagnostico2
	,egresoDiagnostico2_esp

	--,NULL AS RecibioAcyclovir
	--,CentroMedicamentoAmantadina AS RecibioAmantadina
	,CentroMedicamentoAmikacina AS RecibioAmikacina
	,CentroMedicamentoAmoxicilinaAcidoClavulanico AS RecibioAmoxAcidoClavulanico
	,CentroMedicamentoAmoxicilina AS RecibioAmoxicilina
	,CentroMedicamentoAmpicilina AS RecibioAmpicilina
	,CentroMedicamentoAmpicilinaSulbactam AS RecibioAmpicilinaSulbactam
	,CentroMedicamentoAzitromicina AS RecibioAzitromicina
	,NULL  AS RecibioCefadroxil
	,CentroMedicamentoCefalotina AS RecibioCefalotina
	,NULL AS RecibioCefepime
	,CentroMedicamentoCefotaxima AS RecibioCefotaxima
	,CentroMedicamentoCefotriaxone AS RecibioCeftriaxone
	,CentroMedicamentoCefotriaxone AS RecibioCefuroxima
	,CentroMedicamentoCiprofloxacina AS RecibioCiprofloxacina
	,CentroMedicamentoClaritromicina AS RecibioClaritromicina /*INCLUDE*/
	,CentroMedicamentoClindamicina AS RecibioClindamicina
	,CentroMedicamentoCloranfenicol AS RecibioCloranfenicol
	--,CentroMedicamentoDexametazona AS RecibioDexametazona
	,CentroMedicamentoDicloxicina AS RecibioDicloxicina
	,CentroMedicamentoDoxicilina AS RecibioDoxicilina
	,CentroMedicamentoEritromicina AS RecibioEritromicina
	,CentroMedicamentoGentamicina AS RecibioGentamicina
	--,CentroMedicamentoHidrocortizonaSuccinatio AS RecibioHidrocortizonaSuccin
	,NULL AS RecibioImipenem
	--,CentroMedicamentoIsoniacida
	--,CentroMedicamentoLevofloxacina
	--,CentroMedicamentoMeropenem AS RecibioMeropenem
	--,CentroMedicamentoMetilprednisolona AS RecibioMetilprednisolona
	,CentroMedicamentoMetronidazol AS RecibioMetronidazol
	,CentroMedicamentoOfloxacina AS RecibioOfloxacina
	--,CentroMedicamentoOseltamivir AS RecibioOseltamivir
	,CentroMedicamentoOtro AS RecibioOtroAntibiotico
	,CentroRecibidoOtro_esp AS RecibioOtroAntibEspecifique
	,NULL AS RecibioOxacilina
	,CentroMedicamentoPenicilina AS RecibioPenicilina
	--,NULL AS RecibioPerfloxacinia
	,CentroMedicamentoPirazinamida AS RecibioPirazinamida /*INCLUDE*/
	--,CentroMedicamentoPrednisona AS RecibioPrednisona
	,CentroMedicamentoRifampicina AS RecibioRifampicina /*INCLUDE*/
	,CentroMedicamentoTMPSMZ AS RecibioTrimetroprimSulfame
	,CentroMedicamentoVancomicina AS RecibioVancomicina

	--,h7.sueroSalesDurAdmision
	--,h7.liquidosIntravenososDurAdmision
	,seguimientoPacienteCondicion
	-----------------------------------------------


	-- PDA Insert Info
	-----------------------------------------------
	,Sujeto.PDAInsertDate
	,Sujeto.PDAInsertVersion
	-----------------------------------------------


	-- Laboratory Results
	-----------------------------------------------
	,LAB.recepcionMuestraOriginal
	,LAB.recepcionMuestraHisopo
	,LAB.recepcionMuestraPVA
	,LAB.recepcionMuestraFormalina
	,LAB.floranormal
	,LAB.salmonella
	,LAB.salmonellaSp
	,LAB.shigella
	,LAB.shigellaSp
	,LAB.campylobacter
	,LAB.campylobacterSp
	,LAB.otro
	,LAB.pruebaRotavirusHizo
	,LAB.rotavirus
	,LAB.pruebaExamenFrescoHizo
	,LAB.pruebaExamenTricromicoHizo
	,LAB.pruebaExamenIFHizo
	,LAB.ascaris
	,LAB.trichiuris
	,LAB.nana
	,LAB.diminuta
	,LAB.uncinaria
	,LAB.enterobius
	,EntamoebaColi = LAB.ecoli
	,LAB.giardia
	,LAB.crypto
	,LAB.ioda
	,LAB.endolimax
	,LAB.chilo
	,LAB.blasto
	,LAB.NSOP
	,LAB.observaciones
	,LAB.pruebaCultivoHizo
	,LAB.pruebaExamenFrescoSpA
	,LAB.pruebaExamenFrescoSpB
	,LAB.pruebaExamenFrescoSpC
	,LAB.pruebaExamenTricromicoSpA
	,LAB.pruebaExamenTricromicoSpB
	,LAB.pruebaExamenTricromicoSpC
	,LAB.pruebaExamenIFSpA
	,LAB.pruebaExamenIFSpB
	--,LAB.PCREColi
	--,LAB.pruebaPCREColiHizo
	,LAB.pruebaRotavirusTipificacionHizo
	,LAB.rotavirusTipificacion
	,LAB.recepcionMuestraCongeladas
	,LAB.strong
	,LAB.recepcionMuestraNorovirus
	,LAB.Observaciones_UVG
	,LAB.taenia
	-----------------------------------------------


	-- Norovirus
	-----------------------------------------------
	,Norovirus.labNumeroNorovirus
	,Norovirus.fechaExtraccion
	,Norovirus.RTqPCR_RNP
	,Norovirus.RTqPCR_NV1
	,Norovirus.RTqPCR_NV2
	,Norovirus.RTqPCR_RNP_CT
	,Norovirus.RTqPCR_NV1_CT
	,Norovirus.RTqPCR_NV2_CT
	,Norovirus.observaciones AS ObservacionesNorovirus
	-----------------------------------------------


	-- Sensiblidad Antibiotica
	-----------------------------------------------
	,Sensibilidad.pruebaTrimetoprinSulfaSensibilidad
	,Sensibilidad.pruebaTetraciclinaSensibilidad
	,Sensibilidad.pruebaKanamicinaSensibilidad
	,Sensibilidad.pruebaGentamicinaSensibilidad
	,Sensibilidad.pruebaEstreptomicinaSensibilidad
	,Sensibilidad.pruebaCloranfenicolSensibilidad
	,Sensibilidad.pruebaCiprofloxacinaSensiblidad
	,Sensibilidad.pruebaCeftriaxoneSensibilidad
	,Sensibilidad.pruebaAmpicilinaSensibilidad
	,Sensibilidad.pruebaAmoxicilinaSensibilidad
	,Sensibilidad.pruebaAcNalidixicoSensibilidad
	,Sensibilidad.observaciones as ObservacionesSensibilidad
	-----------------------------------------------
	-- E.coli EscheridiaColi
	-----------------------------------------------
	,EscheridiaColi.EPEC
	,EscheridiaColi.ETEC
	,EscheridiaColi.STEC
	-----------------------------------------------
--ASTRO Y SAPO virus 
	  ,[ASTROVIRUS]
      ,[SAPOVIRUS]
      ,[CT_ASTROVIRUS]
      ,[CT_SAPOVIRUS]
      
      
      
FROM Clinicos.Todo_Centro_vw Sujeto
	LEFT JOIN Control.Sitios ON Sujeto.SubjectSiteID = Sitios.SiteID
	LEFT JOIN LegalValue.LV_DEPARTAMENTO NombreDepto ON Sujeto.departamento = NombreDepto.Value
	LEFT JOIN LegalValue.LV_MUNICIPIO NombreMuni ON Sujeto.municipio = NombreMuni.Value
	LEFT JOIN Lab.DiarreaResultados LAB ON Sujeto.SASubjectID = Lab.ID_Paciente
	LEFT JOIN Lab.NorovirusResultados Norovirus ON Sujeto.SASubjectID = Norovirus.ID_Paciente
	LEFT JOIN Lab.DiarreaResultadosAntibiotiocs Sensibilidad ON Sujeto.SASubjectID = Sensibilidad.ID_Paciente

	-- FM[2011-11-10]: Temporal mientras corrigo Todo_Centro
	LEFT JOIN Clinicos.C2L ON C2L.SubjectID = Sujeto.SubjectID AND C2L.forDeletion = 0
	LEFT JOIN Clinicos.C2F ON C2F.SubjectID = Sujeto.SubjectID AND C2F.forDeletion = 0
	LEFT JOIN Lab.EColi_Resultados EscheridiaColi ON EscheridiaColi.SubjectID = Sujeto.SubjectID 
	left JOIN sp.Sindrome_Diarreico sd  on sujeto.SASubjectID collate database_default= sd.SaSubjectID collate database_default
	WHERE Sujeto.forDeletion = 0



UNION ALL



-- Puesto de Salud
SELECT
	Sujeto.[SubjectID]


	-- ID & elegibility
	-----------------------------------------------
	,pacienteInscritoViCo
	,Sujeto.SASubjectID

	,elegibleDiarrea
	,elegibleRespira
	,elegibleNeuro
	,elegibleFebril
	-----------------------------------------------


	-- Dates
	-----------------------------------------------
	,fechaHoraAdmision
	,epiWeekAdmision
	,epiYearAdmision
	-----------------------------------------------


	-- Consent
	-----------------------------------------------
	,consentimientoVerbal
	,consentimientoEscrito
	,asentimientoEscrito
	-----------------------------------------------


	-- Site location
	-----------------------------------------------
	,SubjectSiteID
	,Sitios.TipoSitio AS SiteType
	,Sitios.DeptoShortName AS SiteDepartamento
	-----------------------------------------------


	-- Patient Location
	-----------------------------------------------
	,Sujeto.departamento
	,Sujeto.municipio
	,comunidad
	,HUSarea =
		CASE
			WHEN
				(
					Sujeto.departamento = 6
					AND SubjectSiteID IN (1, 2, 3, 4, 5, 6, 7)
					AND Sujeto.municipio IN (601, 602, 603, 604, 605, 606, 607, 610, 612, 613, 614)
				)
				OR
				(
					Sujeto.departamento = 9
					AND SubjectSiteID IN (9, 12, 13, 14, 15)
					AND Sujeto.municipio IN (901, 902, 903, 909, 910, 911, 913, 914, 916, 923)
				)
				OR
				(
					Sujeto.departamento = 1
					AND SubjectSiteID = 11
				)
			THEN 1
			ELSE 2
		END

	,NombreDepto.Text as NombreDepartamento
	,NombreMuni.Text as NombreMunicipio
	-----------------------------------------------


	-- Demographic
	-----------------------------------------------
	,sexo
	,edadAnios
	,edadMeses
	,edadDias
	,fechaDeNacimiento=convert (date,[fechaDeNacimiento],113)
	,Sujeto.pacienteGrupoEtnico
	-----------------------------------------------


	-- Death information
	-----------------------------------------------
	,muerteViCo =
		CASE
			WHEN egresoTipo  = 4 OR seguimientoPacienteCondicion = 3 THEN 1
			ELSE 2
		END

	,muerteViCoFecha = 
		CASE
			WHEN egresoTipo = 4 THEN Sujeto.PDAInsertDate
			WHEN seguimientoPacienteCondicion = 3 THEN seguimientoPacienteMuerteFecha
			ELSE NULL
		END

	,muerteSospechoso = -- P0, P1CV, P1CE
		CASE
			WHEN ConsentimientoVerbalNoRazonMurio = 1 OR ConsentimientoEscritoMurio = 1 THEN 1
			ELSE 2
		END

	,muerteSospechosoFecha =
		CASE
			WHEN ConsentimientoVerbalNoRazonMurio = 1 OR ConsentimientoEscritoMurio = 1 THEN Sujeto.PDAInsertDate
			ELSE NULL
		END

	,NULL AS muerteHospital

	,muerteCualPaso =
		-- 1 = Tamizaje/Consentimiento
		-- 2 = Durante Entrevista (Inscrito, but NOT everything IS done HCP11 filled out probably)
		-- 3 = Antes de egreso (P7)
		-- 4 = Seguimiento (HCP9)
		CASE	
			WHEN ConsentimientoVerbalNoRazonMurio = 1 OR ConsentimientoEscritoMurio = 1 THEN 1
			WHEN terminoManeraCorrectaNoRazon = 3 THEN 2
			WHEN egresoTipo = 4 THEN 3
			WHEN seguimientoPacienteCondicion = 3THEN 4
			ELSE NULL
		END

	,NULL AS moribundoViCo --P7?
	,NULL AS moribundoViCoFecha --P7?
	,NULL AS moribundoSospechoso
	,NULL AS moribundoSospechosoFecha
	-----------------------------------------------


	-----------------------------------------------
	,presentaIndicacionDiarrea
	,indicacionDiarrea
	,indicacionDiarrea_otra
	,temperaturaPrimeras24Horas
	,NULL AS ingresoPlanBPlanC
	,NULL AS gradoDeshidratacionRegistrado
	,NULL AS gradoDeshidratacion
	,NULL AS conteoGlobulosBlancos
	,NULL AS diferencialAnormal
	,sintomasFiebre
	,sintomasFiebreDias
	,ninioVomitaTodo
	,ninioBeberMamar
	,ninioTuvoConvulsiones
	,ninioTieneLetargia
	,diarreaUltimos7Dias
	,diarreaComenzoHaceDias
	,diarreaMaximoAsientos1Dia
	,diarreaOtroEpisodioSemanaAnterior
	,muestraHecesColecta
	,MuestraHecesNoRazon
	,MuestraHecesNoRazonOtra_esp
	,muestraHecesHisopoSecoNoRazon
	,muestraHecesHisopoSecoNoRazonOtra_esp
	,muestraHecesHisopoSecoFechaHora
	,muestraHecesHisopoCaryBlairColecta
	,muestraHecesHisopoCaryBlairNoRazon
	,muestraHecesHisopoCaryBlairNoRazonOtra_esp
	,muestraHecesHisopoCaryBlairFechaHora
	,muestraHecesHisopoCaryBlairTipo
	,muestraHecesEnteraColecta
	,muestraHecesEnteraNoRazon
	,muestraHecesEnteraNoRazonOtra_Esp
	,muestraHecesEnteraFechaHora
	,muestraHecesEnteraLiquida
	,muestraHecesEnteraCubreFondo
	,hxD_diarreaActual
	,hxD_diarreaActualHaceDias
	,hxD_ConSangre
	,hxD_ConMoco
	,P2L.hxC_Vomitos
	,sintomasEnfermDiarreaVomitos
	,sintomasEnfermDiarreaVomitosVeces
	,sintomasEnfermDiarreaVomitos8Dias
	,sintomasEnfermDiarreaVomitosActual
	,hxD_calambresDolorAbdominal
	,hxD_condicionIntestinal
	,hxD_condicionIntestinal_esp
	,hxD_bebeConSed
	,hxD_irritableIncomodoIntranquilo
	,NULL AS centroRehidratacionTipo
	,otroTratamiento1erRecibioMedicamento
	,otroTratamiento1erAntibioticos
	,otroTratamiento1erSuerosSalesHidracionCasero
	,otroTratamiento2doRecibioMedicamento
	,otroTratamiento2doAntibioticos
	,otroTratamiento2doSuerosSalesHidracionCasero
	,NULL AS otroTratamiento3erRecibioMedicamento
	,NULL AS otroTratamiento3erAntibioticos
	,NULL AS otroTratamiento3erSuerosSalesHidracionCasero
	,medUltimas72HorasAntiB
	,tomadoSuerosSalesUltimas72hora
	,claseSRORecibido
	,enfermedadesCronicasVIHSIDA
	,enfermedadesCronicasOtras
	,enfermedadesCronicasInfoAdicional
	,embarazada
	,embarazadaMeses
	,tieneFichaVacunacion
	,vacunaRotavirusRecibido
	,vacunaRotavirusDosis
	,Sujeto.casaNiniosGuareriaInfantil
	,Sujeto.pacientePachaPecho
	,Sujeto.parentescoGradoEscolarCompleto
	,Sujeto.patienteGradoEscolarCompleto
	,Sujeto.familiaIngresosMensuales
	,Sujeto.fuentesAguaChorroDentroCasaRedPublica
	,Sujeto.fuentesAguaChorroPublico
	,Sujeto.fuentesAguaChorroPatioCompartidoOtraFuente
	,Sujeto.fuentesAguaLavaderosPublicos
	,Sujeto.fuentesAguaPozoPropio
	,Sujeto.fuentesAguaPozoPublico
	,Sujeto.fuentesAguaCompranAguaEmbotellada
	,Sujeto.fuentesAguaDeCamionCisterna
	,Sujeto.fuentesAguaLluvia
	,Sujeto.fuentesAguaRioLago
	,Sujeto.casaAlmacenanAgua
	,Sujeto.aguaLimpiarTratar
	,Sujeto.aguaLimpiarTratarHierven
	,Sujeto.aguaLimpiarTratarQuimicos
	,Sujeto.aguaLimpiarTratarFiltran
	,Sujeto.aguaLimpiarTratarSodis
	,Sujeto.aguaLimpiarTratarOtro
	,Sujeto.aguaLimpiarTratarOtro_esp
	,Sujeto.casaMaterialPiso
	, sujeto.casaEnergiaElectrica
	,Sujeto.casaRefrigeradora
	,Sujeto.casaComputadora
	,Sujeto.casaRadio
	,Sujeto.casaLavadora
	,Sujeto.casaSecadora
	,Sujeto.casaTelefono
	,Sujeto.casaMicroondas
	,Sujeto.casaCarroCamion
	,Sujeto.factoresRiesgoInfoAdicional
	, P2F.combustibleLenia
	, P2F.combustibleResiduosCosecha
	, P2F.combustibleCarbon
	, P2F.combustibleGas
	, P2F.combustibleElectricidad
	, P2F.combustibleOtro
	
	
	
	
	,diarreaExamenFisicoEnfermeraOjos
	,diarreaExamenFisicoEnfermeraMucosaOral
	,diarreaExamenFisicoEnfermeraRellenoCapillar
	,diarreaExamenFisicoEnfermeraPellizcoPiel
	,diarreaExamenFisicoEnfermeraMolleraHundida
	,diarreaExamenFisicoEnfermeraEstadoMental
	,pacienteTallaMedida
	,pacienteTallaCM1
	,pacienteTallaCM2
	,pacienteTallaCM3
	,pacientePesoMedida
	,pacientePesoLibras1
	,pacientePesoLibras2
	,pacientePesoLibras3
	,Sujeto.PDAInsertDate AS egresoMuerteFecha

	,egresoTipo
	,NULL AS egresoCondicion

	,temperaturaPrimeras24Horas AS temperaturaPrimeras24HorasAlta
	,egresoDiagnostico1
	,egresoDiagnostico1_esp
	,egresoDiagnostico2
	,egresoDiagnostico2_esp

	--,NULL AS RecibioAcyclovir
	--,CentroMedicamentoAmantadina AS RecibioAmantadina
	,CentroMedicamentoAmikacina AS RecibioAmikacina
	,CentroMedicamentoAmoxicilinaAcidoClavulanico AS RecibioAmoxAcidoClavulanico
	,CentroMedicamentoAmoxicilina AS RecibioAmoxicilina
	,CentroMedicamentoAmpicilina AS RecibioAmpicilina
	,CentroMedicamentoAmpicilinaSulbactam AS RecibioAmpicilinaSulbactam
	,CentroMedicamentoAzitromicina AS RecibioAzitromicina
	,NULL  AS RecibioCefadroxil
	,CentroMedicamentoCefalotina AS RecibioCefalotina
	,NULL AS RecibioCefepime
	,CentroMedicamentoCefotaxima AS RecibioCefotaxima
	,CentroMedicamentoCefotriaxone AS RecibioCeftriaxone
	,CentroMedicamentoCefotriaxone AS RecibioCefuroxima
	,CentroMedicamentoCiprofloxacina AS RecibioCiprofloxacina
	,CentroMedicamentoClaritromicina AS RecibioClaritromicina /*INCLUDE*/
	,CentroMedicamentoClindamicina AS RecibioClindamicina
	,CentroMedicamentoCloranfenicol AS RecibioCloranfenicol
	--,CentroMedicamentoDexametazona AS RecibioDexametazona
	,CentroMedicamentoDicloxicina AS RecibioDicloxicina
	,CentroMedicamentoDoxicilina AS RecibioDoxicilina
	,CentroMedicamentoEritromicina AS RecibioEritromicina
	,CentroMedicamentoGentamicina AS RecibioGentamicina
	--,CentroMedicamentoHidrocortizonaSuccinatio AS RecibioHidrocortizonaSuccin
	,NULL AS RecibioImipenem
	--,CentroMedicamentoIsoniacida
	--,CentroMedicamentoLevofloxacina
	--,CentroMedicamentoMeropenem AS RecibioMeropenem
	--,CentroMedicamentoMetilprednisolona AS RecibioMetilprednisolona
	,CentroMedicamentoMetronidazol AS RecibioMetronidazol
	,CentroMedicamentoOfloxacina AS RecibioOfloxacina
	--,CentroMedicamentoOseltamivir AS RecibioOseltamivir
	,CentroMedicamentoOtro AS RecibioOtroAntibiotico
	,CentroRecibidoOtro_esp AS RecibioOtroAntibEspecifique
	,NULL AS RecibioOxacilina
	,CentroMedicamentoPenicilina AS RecibioPenicilina
	--,NULL AS RecibioPerfloxacinia
	,CentroMedicamentoPirazinamida AS RecibioPirazinamida /*INCLUDE*/
	--,CentroMedicamentoPrednisona AS RecibioPrednisona
	,CentroMedicamentoRifampicina AS RecibioRifampicina /*INCLUDE*/
	,CentroMedicamentoTMPSMZ AS RecibioTrimetroprimSulfame
	,CentroMedicamentoVancomicina AS RecibioVancomicina

	--,h7.sueroSalesDurAdmision
	--,h7.liquidosIntravenososDurAdmision
	,seguimientoPacienteCondicion
	-----------------------------------------------


	-- PDA Insert Info
	-----------------------------------------------
	,Sujeto.PDAInsertDate
	,Sujeto.PDAInsertVersion
	-----------------------------------------------


	-- Laboratory Results
	-----------------------------------------------
	,LAB.recepcionMuestraOriginal
	,LAB.recepcionMuestraHisopo
	,LAB.recepcionMuestraPVA
	,LAB.recepcionMuestraFormalina
	,LAB.floranormal
	,LAB.salmonella
	,LAB.salmonellaSp
	,LAB.shigella
	,LAB.shigellaSp
	,LAB.campylobacter
	,LAB.campylobacterSp
	,LAB.otro
	,LAB.pruebaRotavirusHizo
	,LAB.rotavirus
	,LAB.pruebaExamenFrescoHizo
	,LAB.pruebaExamenTricromicoHizo
	,LAB.pruebaExamenIFHizo
	,LAB.ascaris
	,LAB.trichiuris
	,LAB.nana
	,LAB.diminuta
	,LAB.uncinaria
	,LAB.enterobius
	,EntamoebaColi = LAB.ecoli
	,LAB.giardia
	,LAB.crypto
	,LAB.ioda
	,LAB.endolimax
	,LAB.chilo
	,LAB.blasto
	,LAB.NSOP
	,LAB.observaciones
	,LAB.pruebaCultivoHizo
	,LAB.pruebaExamenFrescoSpA
	,LAB.pruebaExamenFrescoSpB
	,LAB.pruebaExamenFrescoSpC
	,LAB.pruebaExamenTricromicoSpA
	,LAB.pruebaExamenTricromicoSpB
	,LAB.pruebaExamenTricromicoSpC
	,LAB.pruebaExamenIFSpA
	,LAB.pruebaExamenIFSpB
	--,LAB.PCREColi
	--,LAB.pruebaPCREColiHizo
	,LAB.pruebaRotavirusTipificacionHizo
	,LAB.rotavirusTipificacion
	,LAB.recepcionMuestraCongeladas
	,LAB.strong
	,LAB.recepcionMuestraNorovirus
	,LAB.Observaciones_UVG
	,LAB.taenia
	-----------------------------------------------


	-- Norovirus
	-----------------------------------------------
	,Norovirus.labNumeroNorovirus
	,Norovirus.fechaExtraccion
	,Norovirus.RTqPCR_RNP
	,Norovirus.RTqPCR_NV1
	,Norovirus.RTqPCR_NV2
	,Norovirus.RTqPCR_RNP_CT
	,Norovirus.RTqPCR_NV1_CT
	,Norovirus.RTqPCR_NV2_CT
	,Norovirus.observaciones AS ObservacionesNorovirus
	-----------------------------------------------


	-- Sensiblidad Antibiotica
	-----------------------------------------------
	,Sensibilidad.pruebaTrimetoprinSulfaSensibilidad
	,Sensibilidad.pruebaTetraciclinaSensibilidad
	,Sensibilidad.pruebaKanamicinaSensibilidad
	,Sensibilidad.pruebaGentamicinaSensibilidad
	,Sensibilidad.pruebaEstreptomicinaSensibilidad
	,Sensibilidad.pruebaCloranfenicolSensibilidad
	,Sensibilidad.pruebaCiprofloxacinaSensiblidad
	,Sensibilidad.pruebaCeftriaxoneSensibilidad
	,Sensibilidad.pruebaAmpicilinaSensibilidad
	,Sensibilidad.pruebaAmoxicilinaSensibilidad
	,Sensibilidad.pruebaAcNalidixicoSensibilidad
	,Sensibilidad.observaciones as ObservacionesSensibilidad
	-----------------------------------------------
	-- E.coli EscheridiaColi
	-----------------------------------------------
	,EscheridiaColi.EPEC
	,EscheridiaColi.ETEC
	,EscheridiaColi.STEC
	-----------------------------------------------
	--ASTRO Y SAPO virus 
	  ,[ASTROVIRUS]
      ,[SAPOVIRUS]
      ,[CT_ASTROVIRUS]
      ,[CT_SAPOVIRUS]
	

FROM Clinicos.Todo_Puesto_vw Sujeto
	LEFT JOIN Control.Sitios ON Sujeto.SubjectSiteID = Sitios.SiteID
	LEFT JOIN LegalValue.LV_DEPARTAMENTO NombreDepto ON Sujeto.departamento = NombreDepto.Value
	LEFT JOIN LegalValue.LV_MUNICIPIO NombreMuni ON Sujeto.municipio = NombreMuni.Value
	LEFT JOIN Lab.DiarreaResultados LAB ON Sujeto.SASubjectID = Lab.ID_Paciente
	LEFT JOIN Lab.NorovirusResultados Norovirus ON Sujeto.SASubjectID = Norovirus.ID_Paciente
	LEFT JOIN Lab.DiarreaResultadosAntibiotiocs Sensibilidad ON Sujeto.SASubjectID = Sensibilidad.ID_Paciente

	-- FM[2011-11-10]: Temporal mientras corrigo Todo_Puesto
	LEFT JOIN Clinicos.P2L ON P2L.SubjectID = Sujeto.SubjectID AND P2L.forDeletion = 0
	LEFT JOIN Clinicos.P2f P2F ON P2F.SubjectID = Sujeto.SubjectID AND P2F.forDeletion = 0
	LEFT JOIN Lab.EColi_Resultados EscheridiaColi ON EscheridiaColi.SubjectID = Sujeto.SubjectID
	left JOIN sp.Sindrome_Diarreico sd  on sujeto.SASubjectID collate database_default= sd.SaSubjectID collate database_default
	 
WHERE Sujeto.forDeletion = 0





GO


