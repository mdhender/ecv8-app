/*
 * The accounts section renders whichever child route is active: the list at
 * /admin/accounts, or one account's detail at /admin/accounts/:id. Without this
 * outlet the detail route would match the URL and render nothing.
 */
<template>{{outlet}}</template>
