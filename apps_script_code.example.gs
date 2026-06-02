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
  'link', 'descripcion', 'fechaSeguimiento', 'contacto'
];

// -------------------------------------------------
// GET: fetchAll / fetchDashboard
// -------------------------------------------------

function doGet(e) {
  var action = (e && e.parameter && e.parameter.action) || 'all';

  try {
    var sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);
    var result;

    if (action === 'dashboard') {
      result = getDashboard(sheet);
    } else {
      result = getAllRows(sheet);
    }

    return jsonResponse(result);
  } catch (err) {
    return jsonResponse({ _error: err.toString() }, 500);
  }
}

function getAllRows(sheet) {
  var data = sheet.getDataRange().getValues();
  if (data.length < 2) return [];

  var headers = data[0];
  return data.slice(1)
    .map(function (row, i) {
      return buildRecord(headers, row, i + 2);
    })
    .filter(function (r) {
      return r.empresa || r.vacante;
    });
}

function getDashboard(sheet) {
  var rows = getAllRows(sheet);
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
    var sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME);

    switch (body.action) {
      case 'update':
        return updateRow(sheet, body.rowIndex, body.updates);
      case 'create':
        return createRow(sheet, body.data);
      default:
        return jsonResponse({ _error: 'acción no válida: ' + body.action }, 400);
    }
  } catch (err) {
    return jsonResponse({ _error: err.toString() }, 500);
  }
}

function updateRow(sheet, rowIndex, updates) {
  var headers = sheet.getDataRange().getValues()[0];
  var colMap = buildColMap(headers);

  Object.keys(updates).forEach(function (key) {
    var col = colMap[key];
    if (col != null) {
      sheet.getRange(rowIndex, col + 1).setValue(updates[key]);
    }
  });

  return jsonResponse({ _ok: true, rowIndex: rowIndex });
}

function createRow(sheet, data) {
  var headers = sheet.getDataRange().getValues()[0];
  var colMap = buildColMap(headers);

  var row = COLUMNS.map(function (key) { return data[key] != null ? data[key] : ''; });

  var lastRow = sheet.getLastRow();
  sheet.insertRowAfter(lastRow);
  var newRow = lastRow + 1;

  COLUMNS.forEach(function (key, i) {
    var col = colMap[key];
    if (col != null) {
      sheet.getRange(newRow, col + 1).setValue(data[key] != null ? data[key] : '');
    }
  });

  return jsonResponse({ _ok: true, rowIndex: newRow });
}

// -------------------------------------------------
// HELPERS
// -------------------------------------------------

function buildRecord(headers, row, rowIndex) {
  var record = { _rowIndex: rowIndex };
  for (var i = 0; i < COLUMNS.length && i < headers.length; i++) {
    var value = row[i];
    if (value instanceof Date) {
      record[COLUMNS[i]] = Utilities.formatDate(value, 'GMT-5', 'd/M/yyyy');
    } else {
      record[COLUMNS[i]] = value != null ? String(value) : '';
    }
  }
  return record;
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
    'contacto': 'contacto'
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
