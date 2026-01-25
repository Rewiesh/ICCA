-- Insert script for icca_documents table
-- This script provides examples for inserting document records

-- Example 1: Insert a document with image data (BLOB)
insert into icca_documents (
    name,
    mime_type,
    image_data,
    file_name,
    file_url,
    migrated_data,
    created_by
) values (
    'Audit Report PDF',
    'application/pdf',
    hextoraw('89504E470D0A1A0A'), -- Example binary data (PNG header)
    'audit_report_20260125.pdf',
    '/documents/audit_report_20260125.pdf',
    'N',
    'admin'
);

-- Example 2: Insert a document without image data
insert into icca_documents (
    name,
    mime_type,
    file_name,
    file_url,
    migrated_data,
    created_by
) values (
    'Inspection Form',
    'application/pdf',
    'inspection_form_template.pdf',
    '/documents/inspection_form_template.pdf',
    'N',
    'system'
);

-- Example 3: Insert a migrated document
insert into icca_documents (
    name,
    mime_type,
    file_name,
    file_url,
    migrated_data,
    created_by
) values (
    'Legacy Document',
    'image/jpeg',
    'legacy_doc_001.jpg',
    '/documents/legacy/legacy_doc_001.jpg',
    'Y',
    'migration_user'
);

-- Example 4: Insert multiple documents in one transaction
insert into icca_documents (name, mime_type, file_name, file_url, migrated_data, created_by)
values ('Document 1', 'application/pdf', 'doc1.pdf', '/docs/doc1.pdf', 'N', 'user1');

insert into icca_documents (name, mime_type, file_name, file_url, migrated_data, created_by)
values ('Document 2', 'image/png', 'image2.png', '/docs/image2.png', 'N', 'user1');

insert into icca_documents (name, mime_type, file_name, file_url, migrated_data, created_by)
values ('Document 3', 'image/jpeg', 'photo3.jpg', '/docs/photo3.jpg', 'N', 'user1');

-- Commit transaction
commit;

-- Verify inserted records
select id, name, mime_type, file_name, created_date, created_by 
from icca_documents 
order by id desc;
