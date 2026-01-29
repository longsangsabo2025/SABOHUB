// Temporary fix to update navigation in drawer sections

// Replace all drawer navigation context.push calls with direct navigation:

// For warehouse section:
onTap: () {
  Navigator.pop(context);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const DistributionWarehouseLayout()),
    );
  });
},

// For driver section:
onTap: () {
  Navigator.pop(context);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const DistributionDriverLayout()),
    );
  });
},

// For support section:
onTap: () {
  Navigator.pop(context);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const DistributionCustomerServiceLayout()),
    );
  });
},

// For finance section:
onTap: () {
  Navigator.pop(context);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const DistributionFinanceLayout()),
    );
  });
},