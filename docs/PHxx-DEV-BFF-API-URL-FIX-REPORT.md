# PHxx DEV BFF API URL Fix Report

## Date: 2026-01-22

## Problem: BFF called PROD API instead of DEV API

## Root Cause: NEXT_PUBLIC_* is embedded at BUILD TIME

## Solution: Use RUNTIME env vars API_URL_INTERNAL and API_URL

## Image deployed: phxx-bff-fix-2026012223
