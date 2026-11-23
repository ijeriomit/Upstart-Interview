<template>
  <div role="alert">Failed to load batteries.</div>
  <button type="button" {{on "click" @controller.retry}}>Retry</button>
</template>
