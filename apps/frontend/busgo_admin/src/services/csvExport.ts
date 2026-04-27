/**
 * Trigger a browser download of a CSV file built from an array of rows.
 *
 * @param filenamePrefix - file name without extension; a date suffix is appended
 * @param rows           - array of objects to export. Object keys become CSV headers.
 * @param columns        - optional ordered list of [header, key] pairs for nicer headers
 */
export function exportToCSV<T extends object>(
  filenamePrefix: string,
  rows: T[],
  columns?: Array<[string, keyof T | ((row: T) => unknown)]>,
): void {
  if (rows.length === 0) {
    alert('Nothing to export — the list is empty.');
    return;
  }

  const cols: Array<[string, keyof T | ((row: T) => unknown)]> =
    columns ??
    (Object.keys(rows[0] as object) as Array<keyof T>).map((k) => [String(k), k]);

  const escape = (v: unknown): string => {
    if (v === null || v === undefined) return '';
    const s = typeof v === 'object' ? JSON.stringify(v) : String(v);
    return /[",\n\r]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
  };

  const header = cols.map(([h]) => escape(h)).join(',');
  const body = rows
    .map((row) =>
      cols
        .map(([, key]) =>
          escape(
            typeof key === 'function'
              ? key(row)
              : (row as Record<string, unknown>)[key as string],
          ),
        )
        .join(','),
    )
    .join('\r\n');

  const csv = `${header}\r\n${body}\r\n`;

  const today = new Date().toISOString().slice(0, 10);
  const filename = `${filenamePrefix}_${today}.csv`;

  // BOM so Excel opens UTF-8 correctly.
  const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);

  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  link.style.display = 'none';
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}
