module.exports = async (c) => {
  const s = await c.st(); console.log(JSON.stringify(s.spots.map(x=>[x.id,Math.round(x.x),Math.round(x.y)])), 'miss', JSON.stringify(s.miss.map(Math.round)));
  await c.shot('d');
};
