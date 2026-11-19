/**
 * DevJobs - Google Apps Script API
 *
 * Script vinculado a la Google Sheet de postulaciones.
 * Expone una API REST para que la app Flutter lea y escriba datos.
 *
 * DEPLOY:
 *   1. Abre la hoja → Extensiones → Apps Script
 *   2. Pega este código y guarda (Ctrl+S)
 *   3. Desplegar → Nueva implementación → Web App
 *   4. "Ejecutar como" → Yo  |  "Acceso" → Cualquiera
 *   5. Copia la URL de despliegue y pégala en lib/config.dart
 */

// -------------------------------------------------
// CONFIG
// -------------------------------------------------

 // Reemplaza con el ID real de tu hoja (ver URL del navegador)
// Ejemplo: si la URL es "docs.google.com/spreadsheets/d/abc123/edit", el ID es "abc123"
var SHEET_ID = 'TU_SHEET_ID';
var SHEET_NAME = 'Postulaciones';
var COLUMNS = [
  'fechaPostulacion', 'empresa', 'vacante', 'tipoContrato',
  'modalidad', 'ciudad', 'salarioOfrecido', 'estado',
  'link', 'descripcion', 'fechaSeguimiento', 'contacto', 'comentarios',
  'entrevistaRealizada', 'porGestionar'
];

// Pestaña con el análisis IA por empresa (una fila por empresa).
var SHEET_NAME_INSIGHTS = 'EmpresaAnalisis';
var COMPANY_INSIGHT_COLUMNS = [
  'empresa', 'fechaAnalisis', 'datosAl', 'totalPostulaciones', 'etiquetas',
  'recomendacion', 'resumen', 'fortalezas', 'riesgos', 'perfilVacantes',
  'procesoSeleccion', 'contactos'
];

// Columnas que son fechas reales en la hoja. Al escribirlas se convierten
// a Date explícitamente para que Sheets no las interprete con el locale.
var DATE_COLUMNS = ['fechaPostulacion', 'fechaSeguimiento'];
var COMPANY_INSIGHT_DATE_COLUMNS = ['fechaAnalisis', 'datosAl'];

// -------------------------------------------------
// GET: fetchAll / fetchDashboard
// -------------------------------------------------

function doGet(e) {
  var action = (e && e.parameter && e.parameter.action) || 'all';

  try {
    var ss = SpreadsheetApp.openById(SHEET_ID);
    var sheet = ss.getSheetByName(SHEET_NAME);
    var tz = ss.getSpreadsheetTimeZone();
    var result;

    if (action === 'dashboard') {
      result = getDashboard(sheet, tz);
    } else if (action === 'meta') {
      result = getMeta(ss, sheet);
    } else if (action === 'companyInsights') {
      result = getCompanyInsights(ss);
    } else {
      result = getAllRows(sheet, tz);
    }

    return jsonResponse(result);
  } catch (err) {
    return jsonResponse({ _error: err.toString() }, 500);
  }
}

/** Diagnóstico de solo lectura: zona horaria, locale y formato de las fechas. */
function getMeta(ss, sheet) {
  var headers = sheet.getDataRange().getValues()[0];
  var colMap = buildColMap(headers);
  var firstDataRow = findFirstDataRow(sheet, colMap);

  var filter = sheet.getFilter();
  var filterRange = null;
  if (filter != null) {
    var fr = filter.getRange();
    filterRange = {
      startRow: fr.getRow(),
      endRow: fr.getLastRow()
    };
  }

  return {
    timeZone: ss.getSpreadsheetTimeZone(),
    locale: ss.getSpreadsheetLocale(),
    scriptTimeZone: Session.getScriptTimeZone(),
    fechaPostulacionFormat: sheet.getRange('A2').getNumberFormat(),
    fechaSeguimientoFormat: sheet.getRange('K2').getNumberFormat(),
    lastRow: sheet.getLastRow(),
    lastColumn: sheet.getLastColumn(),
    firstDataRow: firstDataRow,
    filterRange: filterRange
  };
}

function getAllRows(sheet, tz) {
  var data = sheet.getDataRange().getValues();
  if (data.length < 2) return [];

  var headers = data[0];
  return data.slice(1)
    .map(function (row, i) {
      return buildRecord(headers, row, i + 2, tz);
    })
    .filter(function (r) {
      return r.empresa || r.vacante;
    });
}

function getDashboard(sheet, tz) {
  var rows = getAllRows(sheet, tz);
  var estados = rows.map(function (r) { return (r.estado || '').trim().toLowerCase(); });

  return {
    total: rows.length,
    enRevision: count(estados, 'en revisión'),
    entrevistas: count(estados, 'entrevista realizada'),
    ofertas: count(estados, 'oferta recibida') + count(estados, 'ofertas recibidas'),
    rechazadas: count(estados, 'rechazada')
  };
}

// -------------------------------------------------
// POST: update / create
// -------------------------------------------------

function doPost(e) {
  try {
    var body = JSON.parse(e.postData.contents);
    var ss = SpreadsheetApp.openById(SHEET_ID);
    var sheet = ss.getSheetByName(SHEET_NAME);
    var tz = ss.getSpreadsheetTimeZone();

    switch (body.action) {
      case 'update':
        return updateRow(sheet, body.rowIndex, body.updates, tz);
      case 'create':
        return createRow(sheet, body.data, tz);
      case 'upsertCompanyInsight':
        return upsertCompanyInsight(ss, body.data, tz);
      default:
        return jsonResponse({ _error: 'acción no válida: ' + body.action }, 400);
    }
  } catch (err) {
    return jsonResponse({ _error: err.toString() }, 500);
  }
}

function updateRow(sheet, rowIndex, updates, tz) {
  var headers = sheet.getDataRange().getValues()[0];
  var colMap = buildColMap(headers);

  Object.keys(updates).forEach(function (key) {
    var col = colMap[key];
    if (col == null) return;

    var cell = sheet.getRange(rowIndex, col + 1);
    var value = updates[key];

    if (DATE_COLUMNS.indexOf(key) !== -1) {
      value = parseDateForSheet(value, tz);
      if (value === '') {
        cell.clearContent();
        return;
      }
    }

    cell.setValue(value);
  });

  return jsonResponse({ _ok: true, rowIndex: rowIndex });
}

function createRow(sheet, data, tz) {
  var headers = sheet.getDataRange().getValues()[0];
  var colMap = buildColMap(headers);
  var lastColumn = sheet.getLastColumn();

  var firstDataRow = findFirstDataRow(sheet, colMap);
  var hadData = firstDataRow != null;
  if (!hadData) firstDataRow = 2;

  var shifted = true;
  var newRow;

  if (hadData && firstDataRow > 2 &&
      isRowVisibleForData(sheet, firstDataRow - 1) &&
      isRowEmpty(sheet, firstDataRow - 1, lastColumn)) {
    // Hay un hueco justo encima de la primera postulación: lo usamos sin
    // mover filas. Los rowIndex existentes siguen siendo válidos.
    newRow = firstDataRow - 1;
    shifted = false;
    copyRowFormat(sheet, firstDataRow, newRow, lastColumn);
  } else {
    // No hay hueco: insertamos arriba y todo lo demás se desplaza.
    newRow = firstDataRow;
    sheet.insertRowBefore(newRow);
    if (hadData) {
      copyRowFormat(sheet, newRow + 1, newRow, lastColumn);
    }
  }

  COLUMNS.forEach(function (key) {
    var col = colMap[key];
    if (col == null) return;

    var cell = sheet.getRange(newRow, col + 1);
    var value = data[key] != null ? data[key] : '';

    if (DATE_COLUMNS.indexOf(key) !== -1) {
      value = parseDateForSheet(value, tz);
      if (value === '') {
        cell.clearContent();
        return;
      }
    }

    cell.setValue(value);
  });

  return jsonResponse({
    _ok: true,
    rowIndex: newRow,
    shifted: shifted
  });
}

// -------------------------------------------------
// GET companyInsights / POST upsertCompanyInsight
// -------------------------------------------------

/** Filas de la pestaña EmpresaAnalisis (análisis IA por empresa). */
function getCompanyInsights(ss) {
  var sheet = ss.getSheetByName(SHEET_NAME_INSIGHTS);
  if (sheet == null) return [];

  var data = sheet.getDataRange().getValues();
  if (data.length < 2) return [];

  var headers = data[0];
  var colMap = buildInsightColMap(headers);
  var tz = ss.getSpreadsheetTimeZone();

  return data.slice(1)
    .map(function (row) {
      return buildInsightRecord(colMap, row, tz);
    })
    .filter(function (r) {
      return hasText(r.empresa);
    });
}

/**
 * Guarda (o actualiza) el análisis de una empresa.
 * La clave es el nombre de la empresa normalizado (minúsculas + trim):
 * "Acme", "ACME" y " Acme " son la misma fila.
 */
function upsertCompanyInsight(ss, data, tz) {
  if (data == null || !hasText(data.empresa)) {
    return jsonResponse({ _error: 'falta la empresa en los datos' }, 400);
  }

  var sheet = ss.getSheetByName(SHEET_NAME_INSIGHTS);
  if (sheet == null) {
    sheet = ss.insertSheet(SHEET_NAME_INSIGHTS);
    sheet.getRange(1, 1, 1, COMPANY_INSIGHT_COLUMNS.length)
      .setValues([COMPANY_INSIGHT_COLUMNS]);
    sheet.getRange(1, 1, 1, COMPANY_INSIGHT_COLUMNS.length)
      .setFontWeight('bold');
  }

  var headers = sheet.getDataRange().getValues()[0];
  var colMap = buildInsightColMap(headers);
  var key = normalizeInsightKey(data.empresa);
  var row = findInsightRow(sheet, colMap, key);

  if (row == null) {
    row = sheet.getLastRow() + 1;
  }

  COMPANY_INSIGHT_COLUMNS.forEach(function (name) {
    var col = colMap[name];
    if (col == null) return;

    var cell = sheet.getRange(row, col + 1);
    var value = data[name] != null ? data[name] : '';

    if (COMPANY_INSIGHT_DATE_COLUMNS.indexOf(name) !== -1) {
      value = parseDateForSheet(value, tz);
      if (value === '') {
        cell.clearContent();
        return;
      }
    }

    cell.setValue(value);
  });

  return jsonResponse({ _ok: true, rowIndex: row });
}

function normalizeInsightKey(value) {
  return String(value == null ? '' : value).trim().toLowerCase();
}

function buildInsightColMap(headers) {
  var map = {};
  for (var i = 0; i < headers.length; i++) {
    var key = String(headers[i]).trim().toLowerCase();
    for (var j = 0; j < COMPANY_INSIGHT_COLUMNS.length; j++) {
      if (key === COMPANY_INSIGHT_COLUMNS[j].toLowerCase()) {
        map[COMPANY_INSIGHT_COLUMNS[j]] = i;
      }
    }
  }
  COMPANY_INSIGHT_COLUMNS.forEach(function (col) {
    if (map[col] == null) {
      map[col] = COMPANY_INSIGHT_COLUMNS.indexOf(col);
    }
  });
  return map;
}

/** Fila existente del análisis de la empresa (clave normalizada), o null. */
function findInsightRow(sheet, colMap, key) {
  var lastRow = sheet.getLastRow();
  if (lastRow < 2) return null;

  var empresaCol = colMap['empresa'];
  if (empresaCol == null) return null;

  var values = sheet.getRange(2, empresaCol + 1, lastRow - 1, 1).getValues();
  for (var i = 0; i < values.length; i++) {
    if (normalizeInsightKey(values[i][0]) === key) return i + 2;
  }
  return null;
}

function buildInsightRecord(colMap, row, tz) {
  var record = {};
  COMPANY_INSIGHT_COLUMNS.forEach(function (name) {
    var col = colMap[name];
    record[name] = col == null ? '' : formatDateForWire(row[col], tz);
  });
  return record;
}

// -------------------------------------------------
// HELPERS
// -------------------------------------------------

/**
 * Primera fila con una postulación (misma condición que getAllRows).
 * Devuelve null si no hay ninguna.
 */
function findFirstDataRow(sheet, colMap) {
  var lastRow = sheet.getLastRow();
  var lastColumn = sheet.getLastColumn();
  if (lastRow < 2 || lastColumn < 1) return null;

  var empresaCol = colMap['empresa'];
  var vacanteCol = colMap['vacante'];
  var data = sheet.getRange(2, 1, lastRow - 1, lastColumn).getValues();

  for (var i = 0; i < data.length; i++) {
    var empresa = empresaCol != null ? data[i][empresaCol] : '';
    var vacante = vacanteCol != null ? data[i][vacanteCol] : '';
    if (hasText(empresa) || hasText(vacante)) return i + 2;
  }

  return null;
}

function hasText(value) {
  return value != null && String(value).trim() !== '';
}

/**
 * ¿La fila es apta para escribir datos? No debe estar oculta manualmente ni
 * fuera del rango del filtro activo, para que la nueva postulación se vea.
 */
function isRowVisibleForData(sheet, row) {
  if (sheet.isRowHiddenByUser(row)) return false;

  var filter = sheet.getFilter();
  if (filter == null) return true;

  var range = filter.getRange();
  return row >= range.getRow() && row <= range.getLastRow();
}

/** ¿La fila está completamente vacía? (valores, fórmulas y notas). */
function isRowEmpty(sheet, row, lastColumn) {
  if (lastColumn < 1) return true;

  var range = sheet.getRange(row, 1, 1, lastColumn);
  var values = range.getValues()[0];
  var formulas = range.getFormulas()[0];
  var notes = range.getNotes()[0];

  for (var i = 0; i < lastColumn; i++) {
    // Un checkbox desmarcado (false) en una fila plantilla no es dato.
    if (values[i] !== '' && values[i] != null && values[i] !== false) {
      return false;
    }
    if (formulas[i] !== '') return false;
    if (notes[i] !== '') return false;
  }

  return true;
}

/** Copia solo formato y validación de datos entre filas. */
function copyRowFormat(sheet, sourceRow, targetRow, lastColumn) {
  if (lastColumn < 1) return;

  var source = sheet.getRange(sourceRow, 1, 1, lastColumn);
  var target = sheet.getRange(targetRow, 1, 1, lastColumn);
  source.copyTo(target, SpreadsheetApp.CopyPasteType.PASTE_FORMAT, false);
  source.copyTo(
    target,
    SpreadsheetApp.CopyPasteType.PASTE_DATA_VALIDATION,
    false
  );
}

function buildRecord(headers, row, rowIndex, tz) {
  var record = { _rowIndex: rowIndex };
  for (var i = 0; i < COLUMNS.length && i < headers.length; i++) {
    record[COLUMNS[i]] = formatDateForWire(row[i], tz);
  }
  return record;
}

/**
 * Fecha de la hoja -> string de calendario para la app.
 * Usa la zona horaria de la hoja para que el día no se desplace.
 */
function formatDateForWire(value, tz) {
  if (value instanceof Date) {
    return Utilities.formatDate(value, tz, 'd/M/yyyy');
  }
  return value != null ? String(value) : '';
}

/**
 * Fecha que manda la app -> Date real de la hoja.
 *
 * Acepta ISO 'yyyy-MM-dd' (formato nuevo) y 'd/M/yyyy' (compatibilidad).
 * Nunca deja que Sheets interprete el string con el locale de la hoja.
 * Se guarda al mediodía local para blindar el día ante DST o cambios de zona.
 */
function parseDateForSheet(value, tz) {
  if (typeof value !== 'string') return value;

  var v = value.trim();
  if (v === '') return '';

  var iso = /^(\d{4})-(\d{2})-(\d{2})$/.exec(v);
  if (iso) {
    var d = Utilities.parseDate(v, tz, 'yyyy-MM-dd');
    return new Date(d.getTime() + 12 * 60 * 60 * 1000);
  }

  var dmy = /^(\d{1,2})\/(\d{1,2})\/(\d{4})$/.exec(v);
  if (dmy) {
    var d2 = Utilities.parseDate(v, tz, 'd/M/yyyy');
    return new Date(d2.getTime() + 12 * 60 * 60 * 1000);
  }

  return value;
}

/** Ejecutar manualmente desde el editor para validar el round-trip de fechas. */
function testDateRoundTrip() {
  var ss = SpreadsheetApp.openById(SHEET_ID);
  var tz = ss.getSpreadsheetTimeZone();
  ['2026-11-04', '2026-12-25', '2026-12-31', '2027-01-01', '2028-02-29']
    .forEach(function (iso) {
      var back = Utilities.formatDate(parseDateForSheet(iso, tz), tz, 'yyyy-MM-dd');
      if (back !== iso) throw new Error(iso + ' -> ' + back);
    });
  Logger.log('OK: round-trip de fechas válido en ' + tz);
}

function buildColMap(headers) {
  var map = {};
  for (var i = 0; i < headers.length; i++) {
    var key = normalizeColumn(headers[i]);
    if (key) map[key] = i;
  }
  // Ensure all COLUMNS are mapped
  COLUMNS.forEach(function (col) {
    if (map[col] == null) {
      map[col] = COLUMNS.indexOf(col);
    }
  });
  return map;
}

function normalizeColumn(header) {
  var h = header.toString().trim().toLowerCase();
  var map = {
    'fecha postulación': 'fechaPostulacion',
    'fecha postulacion': 'fechaPostulacion',
    'empresa': 'empresa',
    'vacante': 'vacante',
    'tipo de contrato': 'tipoContrato',
    'tipo contrato': 'tipoContrato',
    'modalidad': 'modalidad',
    'ciudad': 'ciudad',
    'salario ofrecido': 'salarioOfrecido',
    'salario': 'salarioOfrecido',
    'estado': 'estado',
    'link': 'link',
    'descripción/notas': 'descripcion',
    'descripcion/notas': 'descripcion',
    'descripción': 'descripcion',
    'descripcion': 'descripcion',
    'notas': 'descripcion',
    'fecha seguimiento': 'fechaSeguimiento',
    'fecha de seguimiento': 'fechaSeguimiento',
    'contacto': 'contacto',
    'comentarios': 'comentarios',
    '¿entrevista?': 'entrevistaRealizada',
    'por gestionar': 'porGestionar'
  };
  return map[h] || null;
}

function count(arr, value) {
  return arr.filter(function (v) { return v === value; }).length;
}

function jsonResponse(data, code) {
  code = code || 200;
  return ContentService.createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}
