#!/usr/bin/python
# -*- coding: utf-8 -*-

"""Custom Jinja2 filters for Cloudflare role."""


class FilterModule(object):
    """Cloudflare custom filters."""

    def filters(self):
        """Return dictionary of filters."""
        return {
            'format_dns_records': self.format_dns_records,
        }

    def format_dns_records(self, dns_records, zone_name):
        """
        Format DNS records for display.
        
        Args:
            dns_records: List of DNS record dictionaries
            zone_name: Zone name to append to record names
            
        Returns:
            List of formatted DNS record strings
        """
        if not dns_records:
            return []
        
        formatted = []
        for record in dns_records:
            name = record.get('name', '')
            content = record.get('content', '')
            record_type = record.get('type', '')
            formatted.append(f"    - {name}.{zone_name} → {content} ({record_type})")
        
        return formatted
